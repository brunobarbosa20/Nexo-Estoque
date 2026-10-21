-- Apply once to a project created with the previous email-based database/supabase.sql.
-- Usernames become the visible login name; each account keeps its own inventory.
begin;

alter table public.profiles add column if not exists username text;
update public.profiles p
   set username = lower(regexp_replace(coalesce(nullif(split_part(coalesce(p.email,''),'@',1),''),'usuario'), '[^a-zA-Z0-9._-]', '_'))
 where username is null or trim(username)='';
alter table public.profiles alter column username set not null;
create unique index if not exists profiles_username_lower_uidx on public.profiles(lower(username));

create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = '' as $$
declare inventory_key uuid; username_value text;
begin
  username_value:=lower(trim(new.raw_user_meta_data->>'username'));
  if username_value is null or username_value='' then username_value:=lower(split_part(coalesce(new.email,''),'@',1)); end if;
  if username_value !~ '^[a-z0-9._-]{3,30}$' then raise exception 'username must contain 3 to 30 letters, numbers, dots, underscores or hyphens'; end if;
  insert into public.profiles(id,email,username) values(new.id,lower(new.email),username_value);
  insert into public.inventory_spaces(name,created_by) values('Estoque de '||username_value,new.id) returning id into inventory_key;
  insert into public.inventory_members(user_id,inventory_id,role) values(new.id,inventory_key,'admin');
  return new;
end; $$;

commit;
