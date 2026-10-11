-- RavieraGroup Portal — execute este arquivo inteiro no Supabase > SQL Editor.
-- As políticas RLS são a proteção real; esconder botões no navegador não é segurança.
create extension if not exists pgcrypto;

create table if not exists public.user_profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null default '',
  role text not null default 'driver' check (role in ('admin','manager','driver')),
  created_at timestamptz not null default now()
);

create table if not exists public.drivers (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  qra text not null unique,
  money text not null default '',
  truck text not null default '',
  trailer text not null default '',
  license text not null default '',
  fines text not null default '',
  updated_at timestamptz not null default now(),
  updated_by uuid references auth.users(id) on delete set null
);

create index if not exists drivers_name_idx on public.drivers (name);

-- Registra automaticamente novos usuários como motoristas, sem dar privilégios.
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = ''
as $$
begin
  insert into public.user_profiles (id, display_name, role)
  values (new.id, coalesce(new.raw_user_meta_data ->> 'display_name', split_part(new.email, '@', 1)), 'driver')
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created_raviera on auth.users;
create trigger on_auth_user_created_raviera
after insert on auth.users
for each row execute procedure public.handle_new_user();

-- Função SECURITY DEFINER evita recursão nas políticas da própria user_profiles.
create or replace function public.is_raviera_staff()
returns boolean language sql stable security definer set search_path = ''
as $$
  select exists (
    select 1 from public.user_profiles up
    where up.id = (select auth.uid()) and up.role in ('admin','manager')
  );
$$;

alter table public.user_profiles enable row level security;
alter table public.drivers enable row level security;

drop policy if exists "users read own profile or staff" on public.user_profiles;
create policy "users read own profile or staff"
on public.user_profiles for select to authenticated
using (id = (select auth.uid()) or public.is_raviera_staff());

-- Nenhuma política de INSERT/UPDATE/DELETE para user_profiles no cliente:
-- cargos são atribuídos pelo administrador no SQL Editor do Supabase.
drop policy if exists "authenticated users read drivers" on public.drivers;
create policy "authenticated users read drivers"
on public.drivers for select to authenticated using (true);

drop policy if exists "staff insert drivers" on public.drivers;
create policy "staff insert drivers"
on public.drivers for insert to authenticated
with check (public.is_raviera_staff());

drop policy if exists "staff update drivers" on public.drivers;
create policy "staff update drivers"
on public.drivers for update to authenticated
using (public.is_raviera_staff())
with check (public.is_raviera_staff());

drop policy if exists "staff delete drivers" on public.drivers;
create policy "staff delete drivers"
on public.drivers for delete to authenticated
using (public.is_raviera_staff());

-- Carga inicial. Repetir o script não duplica QRA.
insert into public.drivers (name, qra, money, truck, trailer, license, fines)
values
 ('Wallace','RAV-WALLACE','A definir','A definir','A definir','A definir','A definir'),
 ('Oliver','RAV-OLIVER','A definir','A definir','A definir','A definir','A definir'),
 ('Leozin','RAV-LEOZIN','A definir','A definir','A definir','A definir','A definir'),
 ('Leo','RAV-LEO','A definir','A definir','A definir','A definir','A definir'),
 ('Gustavo','RAV-GUSTAVO','A definir','A definir','A definir','A definir','A definir'),
 ('Jahir','RAV-JAHIR','A definir','A definir','A definir','A definir','A definir')
on conflict (qra) do nothing;

-- IMPORTANTE: depois de criar o primeiro usuário no Authentication, use o SQL abaixo
-- substituindo o e-mail. Faça o mesmo para cada gerente.
-- update public.user_profiles up
-- set role = 'admin', display_name = 'Administrador Raviera'
-- from auth.users au where au.id = up.id and au.email = 'SEU-EMAIL@EXEMPLO.COM';
--
-- Para dar acesso de gerente:
-- update public.user_profiles up
-- set role = 'manager', display_name = 'Nome do Gerente'
-- from auth.users au where au.id = up.id and au.email = 'EMAIL-DO-GERENTE@EXEMPLO.COM';
