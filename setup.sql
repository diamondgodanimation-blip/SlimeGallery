-- SLIMEVAULT DATABASE SETUP
-- Run this entire script in Supabase Dashboard > SQL Editor.
-- Then create/sign in to your app account and follow the admin promotion step in SETUP.md.

create extension if not exists pgcrypto;

create table if not exists public.vault_admins (
  user_id uuid primary key references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);

alter table public.vault_admins enable row level security;
drop policy if exists "Admins can read own admin record" on public.vault_admins;
create policy "Admins can read own admin record"
on public.vault_admins for select to authenticated
using (user_id = auth.uid());

create or replace function public.is_vault_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.vault_admins
    where user_id = (select auth.uid())
  );
$$;
revoke all on function public.is_vault_admin() from public;
grant execute on function public.is_vault_admin() to anon, authenticated;

create table if not exists public.folders (
  id uuid primary key default gen_random_uuid(),
  name text not null check (char_length(name) between 1 and 45),
  owner_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);

create table if not exists public.assets (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  kind text not null check (kind in ('image','video','audio')),
  description text not null default '',
  tags text[] not null default '{}',
  folder_id uuid references public.folders(id) on delete set null,
  storage_path text not null unique,
  public_url text not null,
  mime_type text not null,
  size_bytes bigint not null default 0,
  is_favorite boolean not null default false,
  owner_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);

alter table public.folders enable row level security;
alter table public.assets enable row level security;

drop policy if exists "Public can view folders" on public.folders;
create policy "Public can view folders" on public.folders
for select to anon, authenticated using (true);
drop policy if exists "Vault admins manage folders" on public.folders;
create policy "Vault admins manage folders" on public.folders
for all to authenticated
using (public.is_vault_admin() and owner_id = auth.uid())
with check (public.is_vault_admin() and owner_id = auth.uid());

drop policy if exists "Public can view assets" on public.assets;
create policy "Public can view assets" on public.assets
for select to anon, authenticated using (true);
drop policy if exists "Vault admins manage assets" on public.assets;
create policy "Vault admins manage assets" on public.assets
for all to authenticated
using (public.is_vault_admin() and owner_id = auth.uid())
with check (public.is_vault_admin() and owner_id = auth.uid());

grant select on public.folders, public.assets to anon, authenticated;
grant insert, update, delete on public.folders, public.assets to authenticated;

-- Public bucket: anyone with a file URL can view/download media.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'slimevault',
  'slimevault',
  true,
  52428800,
  array[
    'image/jpeg','image/png','image/webp','image/gif','image/avif',
    'video/mp4','video/webm','video/quicktime',
    'audio/mpeg','audio/mp4','audio/aac','audio/ogg','audio/wav','audio/webm'
  ]
)
on conflict (id) do update set
  public = true,
  file_size_limit = 52428800,
  allowed_mime_types = excluded.allowed_mime_types;

-- Public read is supplied by the public bucket. Writes remain administrator-only.
drop policy if exists "Vault admins upload SlimeVault files" on storage.objects;
create policy "Vault admins upload SlimeVault files"
on storage.objects for insert to authenticated
with check (bucket_id = 'slimevault' and public.is_vault_admin());

drop policy if exists "Vault admins update SlimeVault files" on storage.objects;
create policy "Vault admins update SlimeVault files"
on storage.objects for update to authenticated
using (bucket_id = 'slimevault' and public.is_vault_admin())
with check (bucket_id = 'slimevault' and public.is_vault_admin());

drop policy if exists "Vault admins delete SlimeVault files" on storage.objects;
create policy "Vault admins delete SlimeVault files"
on storage.objects for delete to authenticated
using (bucket_id = 'slimevault' and public.is_vault_admin());
