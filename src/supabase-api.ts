import { createClient } from "@supabase/supabase-js";

const url = import.meta.env.VITE_SUPABASE_URL as string | undefined;
const anonKey = import.meta.env.VITE_SUPABASE_ANON_KEY as string | undefined;

export const supabase = createClient(url || "https://missing.supabase.co", anonKey || "missing-anon-key");

type RequestBody = Record<string, any>;
const fail = (error: { message: string } | null) => { if (error) throw new Error(error.message); };
const bodyOf = (init?: RequestInit): RequestBody => init?.body ? JSON.parse(String(init.body)) : {};
const methodOf = (init?: RequestInit) => init?.method?.toUpperCase() ?? "GET";
function authEmail(usernameInput: unknown) {
  const username = String(usernameInput ?? "").trim().toLowerCase();
  if (!/^[a-z0-9._-]{3,30}$/.test(username)) throw new Error("Use um nome com 3 a 30 letras sem acentos, números, ponto, sublinhado ou hífen.");
  return `${username}@login.controle-estoque.invalid`;
}

async function sessionUser() {
  const { data: { session }, error } = await supabase.auth.getSession();
  fail(error);

  const user = session?.user;
  if (!user) return null;

  const { data: member, error: memberError } = await supabase
    .from("inventory_members")
    .select("role,inventory_id")
    .eq("user_id", user.id)
    .single();

  fail(memberError);

  const { data: profile, error: profileError } = await supabase
    .from("profiles")
    .select("username")
    .eq("id", user.id)
    .single();

  fail(profileError);

  if (!member) {
    throw new Error("Membro não encontrado.");
  }

  if (!profile) {
    throw new Error("Perfil não encontrado.");
  }

  return {
    id: user.id,
    email: profile.username,
    role: member.role,
    inventoryId: member.inventory_id
  };
}

async function data<T>(query: any): Promise<T> {
    const result = await query;
    fail(result.error);
    return result.data;
  }

export async function api<T>(path: string, init?: RequestInit): Promise<T> {
  if (!url || !anonKey) throw new Error("Configure VITE_SUPABASE_URL e VITE_SUPABASE_ANON_KEY no arquivo .env.");
  const method = methodOf(init);
  const body = bodyOf(init);

  if (path === "/api/session") return { user: await sessionUser() } as T;
  if (path === "/api/auth/register" && method === "POST") {
    const username = String(body.username).trim().toLowerCase();
    const { error } = await supabase.auth.signUp({
      email: authEmail(username),
      password: body.password,
      options: { data: { username } },
    });
    if (error?.message === "Database error saving new user") {
      throw new Error("Esse nome pode estar reservado por um cadastro anterior. Tente outro, como bruno_estoque. Se o erro continuar, confirme que database/supabase_username_migration.sql foi executado no Supabase.");
    }
    if (error?.message?.toLowerCase().includes("email rate limit exceeded")) {
      throw new Error("O Supabase está tentando enviar e-mail de confirmação e atingiu o limite. No painel, abra Authentication > Providers > Email e desative Confirm email; depois tente novamente. Como o limite já foi atingido, aguarde a liberação antes de novos cadastros.");
    }
    fail(error);
    return {} as T;
  }
  if (path === "/api/auth/login" && method === "POST") {
    const { error } = await supabase.auth.signInWithPassword({ email: authEmail(body.username), password: body.password });
    fail(error);
    return {} as T;
  }
  if (path === "/api/auth/logout") {
    const { error } = await supabase.auth.signOut(); fail(error); return { ok: true } as T;
  }

  if (path === "/api/products" && method === "GET") {
    const rows = await data<any[]>(supabase.from("products").select("*,movements(quantity,unit_price,type,note)").order("created_at", { ascending: false }));
    return rows.map(row => {
      const entries = (row.movements ?? []).filter((m: any) => m.type === "entrada" && m.note !== "Saldo inicial");
      const totalQuantity = entries.reduce((n: number, m: any) => n + Number(m.quantity), 0);
      const averageUnitCost = totalQuantity ? entries.reduce((n: number, m: any) => n + Number(m.quantity) * Number(m.unit_price), 0) / totalQuantity : null;
      const { movements, ...p } = row;
      return { ...p, pendingRegistration: p.pending_registration, gramsPerUnit: p.grams_per_unit, averageUnitCost };
    }) as T;
  }
  if (path === "/api/products" && method === "POST") {
    return data(supabase.rpc("create_product", { p_name: body.name, p_unit: body.unit, p_notes: body.notes ?? "", p_initial: body.initialQuantity ?? 0 })) as T;
  }
  if ((path === "/api/movements" || path.startsWith("/api/movements?")) && method === "GET") {
    const productId = new URLSearchParams(path.split("?", 2)[1] ?? "").get("productId");
    let query = supabase.from("movements").select("*,products!inner(id,name,unit)").order("created_at", { ascending: false });
    if (productId) query = query.eq("product_id", productId);
    else query = query.limit(50);
    const rows = await data<any[]>(query);
    const ids = [...new Set(rows.map(r => r.created_by))];
    const profiles = ids.length ? await data<any[]>(supabase.from("profiles").select("id,username").in("id", ids)) : [];
    const usernames = new Map(profiles.map(p => [p.id, p.username]));
    return rows.map(r => ({ id: r.id, type: r.type, quantity: r.quantity, unitPrice: r.unit_price, note: r.note, createdAt: r.created_at, createdByEmail: usernames.get(r.created_by), productId: r.products.id, productName: r.products.name, unit: r.products.unit })) as T;
  }
  if (path === "/api/movements" && method === "POST") {
    return data(supabase.rpc("append_movement", { p_product_id: body.productId, p_type: body.type, p_quantity: body.quantity, p_unit_price: body.unitPrice ?? 0, p_note: body.note ?? "" })) as T;
  }

  const productAction = path.match(/^\/api\/products\/([^/]+)\/(active|cancel|finalize)$/);
  if (productAction && method === "POST") {
    const [_, id, action] = productAction;
    const value = action === "active" ? body.active : action === "cancel" ? body.cancelled : true;
    return data(supabase.rpc("set_product_state", { p_product_id: decodeURIComponent(id), p_action: action, p_value: value })) as T;
  }
  const productPatch = path.match(/^\/api\/products\/([^/]+)$/);
  if (productPatch && method === "PATCH") {
    return data(supabase.rpc("edit_product", { p_product_id: decodeURIComponent(productPatch[1]), p_name: body.name, p_notes: body.notes ?? "", p_grams: body.gramsPerUnit ?? null })) as T;
  }

  if (path === "/api/recipes" && method === "GET") {
    const rows = await data<any[]>(supabase.from("recipes").select("*,recipe_ingredients(*)").order("created_at", { ascending: false }));
    return rows.map(r => ({ id: r.id, name: r.name, portions: r.portions, createdBy: r.created_by, createdAt: r.created_at, ingredients: r.recipe_ingredients.map((i: any) => ({ id: i.id, name: i.name, quantity: i.quantity, unit: i.unit, productId: i.product_id })) })) as T;
  }
  const recipePath = path.match(/^\/api\/recipes(?:\/([^/]+))?$/);
  if (recipePath && (method === "POST" || method === "PUT")) {
    const id = method === "PUT" ? decodeURIComponent(recipePath[1] ?? "") : null;
    if (method === "PUT" && !id) throw new Error("Identificador da receita inválido.");
    const ingredients = (body.ingredients ?? []).map((i: any, position: number) => ({ ...i, product_id: i.productId ?? null, position }));
    return data(supabase.rpc("save_recipe", { p_recipe_id: id, p_name: body.name, p_portions: body.portions, p_ingredients: ingredients })) as T;
  }
  if (recipePath && method === "DELETE") return data(supabase.rpc("delete_recipe", { p_recipe_id: decodeURIComponent(recipePath[1]) })) as T;

  throw new Error("Operação não implementada no Supabase.");
}
