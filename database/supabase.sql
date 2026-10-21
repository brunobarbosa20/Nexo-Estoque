-- Supabase schema for Controle de Estoque.
-- Run once in the Supabase SQL Editor on a new project.

create extension if not exists pgcrypto;

create table public.inventory_spaces (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  created_by uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  username text not null,
  email text,
  created_at timestamptz not null default now()
);

create table public.inventory_members (
  user_id uuid primary key references auth.users(id) on delete cascade,
  inventory_id uuid not null references public.inventory_spaces(id) on delete cascade,
  role text not null default 'admin' check (role in ('admin','operator','viewer')),
  created_at timestamptz not null default now()
);

create table public.products (
  id uuid primary key default gen_random_uuid(),
  inventory_id uuid not null references public.inventory_spaces(id) on delete cascade,
  created_by uuid not null references auth.users(id),
  code text not null default '',
  name text not null,
  unit text not null check (unit in ('UN','GR','ML')),
  quantity integer not null default 0 check (quantity >= 0),
  notes text not null default '',
  active boolean not null default true,
  cancelled boolean not null default false,
  pending_registration boolean not null default false,
  grams_per_unit integer check (grams_per_unit is null or grams_per_unit > 0),
  created_at timestamptz not null default now()
);

create table public.movements (
  id uuid primary key default gen_random_uuid(),
  product_id uuid not null references public.products(id) on delete restrict,
  created_by uuid not null references auth.users(id),
  type text not null check (type in ('entrada','saida')),
  quantity integer not null check (quantity > 0),
  unit_price numeric(18,6) not null default 0 check (unit_price >= 0),
  note text,
  created_at timestamptz not null default now()
);

create table public.recipes (
  id uuid primary key default gen_random_uuid(),
  inventory_id uuid not null references public.inventory_spaces(id) on delete cascade,
  created_by uuid not null references auth.users(id),
  name text not null,
  portions integer not null check (portions > 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.recipe_ingredients (
  id uuid primary key default gen_random_uuid(),
  recipe_id uuid not null references public.recipes(id) on delete cascade,
  product_id uuid references public.products(id) on delete set null,
  name text not null,
  quantity integer not null check (quantity > 0),
  unit text not null check (unit in ('UN','GR','ML')),
  position integer not null default 0
);

create index products_inventory_created_idx on public.products(inventory_id, created_at desc);
create unique index profiles_username_lower_uidx on public.profiles(lower(username));
create index movements_product_created_idx on public.movements(product_id, created_at desc);
create index recipes_inventory_created_idx on public.recipes(inventory_id, created_at desc);
create index recipe_ingredients_recipe_idx on public.recipe_ingredients(recipe_id, position);

create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = '' as $$
declare inventory_key uuid; username_value text;
begin
  username_value:=nullif(trim(new.raw_user_meta_data->>'username'),'');
  if username_value is null then username_value:=coalesce(nullif(split_part(coalesce(new.email,''),'@',1),''),'Usuário '||left(new.id::text,8)); end if;
  username_value:=lower(username_value);
  if username_value !~ '^[a-z0-9._-]{3,30}$' then raise exception 'username must contain 3 to 30 letters, numbers, dots, underscores or hyphens'; end if;
  insert into public.profiles(id,email,username) values(new.id,lower(new.email),username_value);
  insert into public.inventory_spaces(name,created_by) values('Estoque de '||username_value,new.id) returning id into inventory_key;
  insert into public.inventory_members(user_id,inventory_id,role) values(new.id,inventory_key,'admin');
  return new;
end; $$;

create trigger on_auth_user_created after insert on auth.users
for each row execute procedure public.handle_new_user();

create or replace function public.my_inventory_id()
returns uuid language sql stable security definer set search_path = '' as $$
  select inventory_id from public.inventory_members where user_id = (select auth.uid())
$$;

create or replace function public.my_inventory_role()
returns text language sql stable security definer set search_path = '' as $$
  select role from public.inventory_members where user_id = (select auth.uid())
$$;

create or replace function public.apply_movement()
returns trigger language plpgsql security definer set search_path = '' as $$
declare current_quantity integer; target_inventory uuid;
begin
  select quantity, inventory_id into current_quantity, target_inventory
    from public.products where id=new.product_id for update;
  if target_inventory is null or target_inventory <> public.my_inventory_id() then
    raise exception 'product not found in your inventory';
  end if;
  if new.type='saida' and current_quantity < new.quantity then raise exception 'insufficient stock'; end if;
  update public.products set quantity = quantity + case when new.type='entrada' then new.quantity else -new.quantity end
    where id=new.product_id;
  return new;
end; $$;

create trigger movements_apply_stock before insert on public.movements
for each row execute procedure public.apply_movement();

alter table public.inventory_spaces enable row level security;
alter table public.profiles enable row level security;
alter table public.inventory_members enable row level security;
alter table public.products enable row level security;
alter table public.movements enable row level security;
alter table public.recipes enable row level security;
alter table public.recipe_ingredients enable row level security;

create policy inventory_spaces_read on public.inventory_spaces for select to authenticated using (id=public.my_inventory_id());
create policy profiles_read on public.profiles for select to authenticated
  using (id=auth.uid() or id in (select user_id from public.inventory_members where inventory_id=public.my_inventory_id()));
create policy members_read on public.inventory_members for select to authenticated
  using (inventory_id=public.my_inventory_id());
create policy products_read on public.products for select to authenticated
  using (inventory_id=public.my_inventory_id());
create policy movements_read on public.movements for select to authenticated
  using (exists(select 1 from public.products p where p.id=product_id and p.inventory_id=public.my_inventory_id()));
create policy recipes_read on public.recipes for select to authenticated
  using (inventory_id=public.my_inventory_id());
create policy ingredients_read on public.recipe_ingredients for select to authenticated
  using (exists(select 1 from public.recipes r where r.id=recipe_id and r.inventory_id=public.my_inventory_id()));

create or replace function public.create_product(p_name text,p_unit text,p_notes text,p_initial integer)
returns uuid language plpgsql security definer set search_path = '' as $$
declare new_id uuid; inv uuid;
begin
  if public.my_inventory_role() not in ('admin','operator') then raise exception 'operator role required'; end if;
  if p_unit not in ('UN','GR','ML') or p_initial < 0 then raise exception 'invalid product data'; end if;
  inv:=public.my_inventory_id();
  insert into public.products(inventory_id,created_by,name,unit,notes) values(inv,auth.uid(),trim(p_name),p_unit,coalesce(trim(p_notes),'')) returning id into new_id;
  if p_initial>0 then
    insert into public.movements(product_id,created_by,type,quantity,unit_price,note)
      values(new_id,auth.uid(),'entrada',p_initial,0,'Saldo inicial');
  end if;
  return new_id;
end; $$;

create or replace function public.append_movement(p_product_id uuid,p_type text,p_quantity integer,p_unit_price numeric,p_note text)
returns uuid language plpgsql security definer set search_path = '' as $$
declare new_id uuid;
begin
  if public.my_inventory_role() not in ('admin','operator') then raise exception 'operator role required'; end if;
  if p_type not in ('entrada','saida') or p_quantity<=0 or p_unit_price<0 then raise exception 'invalid movement'; end if;
  insert into public.movements(product_id,created_by,type,quantity,unit_price,note)
    values(p_product_id,auth.uid(),p_type,p_quantity,coalesce(p_unit_price,0),nullif(trim(p_note),'')) returning id into new_id;
  return new_id;
end; $$;

create or replace function public.edit_product(p_product_id uuid,p_name text,p_notes text,p_grams integer)
returns void language plpgsql security definer set search_path = '' as $$
begin
  if public.my_inventory_role() not in ('admin','operator') then raise exception 'operator role required'; end if;
  update public.products set name=trim(p_name),notes=coalesce(trim(p_notes),''),grams_per_unit=p_grams
    where id=p_product_id and inventory_id=public.my_inventory_id();
  if not found then raise exception 'product not found'; end if;
end; $$;

create or replace function public.set_product_state(p_product_id uuid,p_action text,p_value boolean default true)
returns void language plpgsql security definer set search_path = '' as $$
declare product_quantity integer; product_cancelled boolean; product_pending boolean;
begin
  if public.my_inventory_role() not in ('admin','operator') then raise exception 'operator role required'; end if;
  if p_action='active' then
    select quantity,cancelled,pending_registration into product_quantity,product_cancelled,product_pending
      from public.products where id=p_product_id and inventory_id=public.my_inventory_id() for update;
    if product_quantity is null then raise exception 'product not found'; end if;
    if product_cancelled or product_pending then raise exception 'restore cancelled product or finalize preregistration first'; end if;
    if not p_value and product_quantity<>0 then raise exception 'stock must be zero before deactivation'; end if;
    update public.products set active=p_value where id=p_product_id and inventory_id=public.my_inventory_id();
  elsif p_action='cancel' then update public.products set cancelled=p_value where id=p_product_id and inventory_id=public.my_inventory_id();
  elsif p_action='finalize' then update public.products set pending_registration=false where id=p_product_id and inventory_id=public.my_inventory_id() and pending_registration;
  else raise exception 'invalid action'; end if;
  if not found then raise exception 'product not found'; end if;
end; $$;

create or replace function public.save_recipe(p_recipe_id uuid,p_name text,p_portions integer,p_ingredients jsonb)
returns uuid language plpgsql security definer set search_path = '' as $$
declare rid uuid; inv uuid; item jsonb; ingredient_name text; ingredient_unit text; ingredient_product uuid;
  product_name text; product_unit text; product_active boolean; product_cancelled boolean; product_grams integer;
begin
  if p_portions<=0 or jsonb_typeof(p_ingredients)<>'array' or jsonb_array_length(p_ingredients)<1 or jsonb_array_length(p_ingredients)>200 then raise exception 'invalid recipe'; end if;
  inv:=public.my_inventory_id();
  if p_recipe_id is null then
    insert into public.recipes(inventory_id,created_by,name,portions) values(inv,auth.uid(),trim(p_name),p_portions) returning id into rid;
  else
    update public.recipes set name=trim(p_name),portions=p_portions,updated_at=now()
      where id=p_recipe_id and inventory_id=inv and created_by=auth.uid() returning id into rid;
    if rid is null then raise exception 'recipe not found'; end if;
    delete from public.recipe_ingredients where recipe_id=rid;
  end if;
  for item in select value from jsonb_array_elements(p_ingredients) loop
    ingredient_name:=trim(item->>'name'); ingredient_unit:=item->>'unit';
    if ingredient_name='' or ingredient_unit not in ('UN','GR','ML') or (item->>'quantity')::integer<=0 then raise exception 'invalid ingredient'; end if;
    ingredient_product:=nullif(item->>'product_id','')::uuid;
    if ingredient_product is not null then
      select name,unit,active,cancelled,grams_per_unit into product_name,product_unit,product_active,product_cancelled,product_grams
        from public.products where id=ingredient_product and inventory_id=inv;
      if product_name is null then raise exception 'ingredient product belongs to another inventory'; end if;
      if not product_active or product_cancelled then raise exception 'ingredient product is unavailable'; end if;
      if product_name<>ingredient_name then raise exception 'ingredient name must match product'; end if;
      if product_unit<>ingredient_unit and not (product_unit='GR' and ingredient_unit='UN' and product_grams is not null) then raise exception 'ingredient unit does not match product'; end if;
    end if;
    if ingredient_product is null and public.my_inventory_role() in ('admin','operator') and not exists(select 1 from public.products where inventory_id=inv and lower(name)=lower(ingredient_name)) then
      insert into public.products(inventory_id,created_by,name,unit,code,notes,pending_registration)
        values(inv,auth.uid(),ingredient_name,ingredient_unit,'','',true) returning id into ingredient_product;
    end if;
    insert into public.recipe_ingredients(recipe_id,product_id,name,quantity,unit,position)
      values(rid,ingredient_product,ingredient_name,(item->>'quantity')::integer,ingredient_unit,coalesce((item->>'position')::integer,0));
  end loop;
  return rid;
end; $$;

create or replace function public.delete_recipe(p_recipe_id uuid)
returns void language plpgsql security definer set search_path = '' as $$
begin
  delete from public.recipes where id=p_recipe_id and inventory_id=public.my_inventory_id() and created_by=auth.uid();
  if not found then raise exception 'recipe not found'; end if;
end; $$;

create or replace function public.set_inventory_role(p_user_id uuid,p_role text)
returns void language plpgsql security definer set search_path = '' as $$
declare old_role text; admin_count integer;
begin
  if public.my_inventory_role()<>'admin' or p_role not in ('admin','operator','viewer') then raise exception 'admin role required or invalid role'; end if;
  select role into old_role from public.inventory_members where user_id=p_user_id and inventory_id=public.my_inventory_id() for update;
  if old_role is null then raise exception 'member not found'; end if;
  if old_role='admin' and p_role<>'admin' then
    select count(*) into admin_count from public.inventory_members where inventory_id=public.my_inventory_id() and role='admin';
    if admin_count<=1 then raise exception 'at least one admin must remain'; end if;
  end if;
  update public.inventory_members set role=p_role where user_id=p_user_id and inventory_id=public.my_inventory_id();
end; $$;

revoke all on public.inventory_spaces,public.profiles,public.inventory_members,public.products,public.movements,public.recipes,public.recipe_ingredients from anon,authenticated;
grant select on public.inventory_spaces,public.profiles,public.inventory_members,public.products,public.movements,public.recipes,public.recipe_ingredients to authenticated;
revoke all on function public.my_inventory_id(),public.my_inventory_role(),public.create_product(text,text,text,integer),public.append_movement(uuid,text,integer,numeric,text),public.edit_product(uuid,text,text,integer),public.set_product_state(uuid,text,boolean),public.save_recipe(uuid,text,integer,jsonb),public.delete_recipe(uuid),public.set_inventory_role(uuid,text) from public,anon;
grant execute on function public.my_inventory_id(),public.my_inventory_role(),public.create_product(text,text,text,integer),public.append_movement(uuid,text,integer,numeric,text),public.edit_product(uuid,text,text,integer),public.set_product_state(uuid,text,boolean),public.save_recipe(uuid,text,integer,jsonb),public.delete_recipe(uuid),public.set_inventory_role(uuid,text) to authenticated;
revoke all on function public.handle_new_user(),public.apply_movement() from public,anon,authenticated;

