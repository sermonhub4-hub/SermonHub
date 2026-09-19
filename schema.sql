-- SermonHub core database schema.
-- Run this in Supabase SQL Editor.

create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text,
  avatar_url text,
  role text not null default 'user' check (role in ('user','admin')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.categories (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  slug text not null unique,
  created_at timestamptz not null default now()
);

create table if not exists public.preachers (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  bio text,
  image_url text,
  created_at timestamptz not null default now()
);

create table if not exists public.sermons (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  slug text not null unique,
  description text,
  thumbnail_url text,
  video_url text,
  audio_url text,
  preacher_id uuid references public.preachers(id) on delete set null,
  category_id uuid references public.categories(id) on delete set null,
  scripture text,
  views bigint not null default 0,
  published boolean not null default false,
  featured boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.favorites (
  user_id uuid references auth.users(id) on delete cascade,
  sermon_id uuid references public.sermons(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key(user_id,sermon_id)
);

create table if not exists public.live_streams (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  stream_url text,
  thumbnail_url text,
  is_live boolean not null default false,
  started_at timestamptz,
  created_at timestamptz not null default now()
);

create table if not exists public.admin_users (
  user_id uuid primary key references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);

create or replace function public.handle_new_user() returns trigger
language plpgsql security definer set search_path=public as $$
begin
  insert into public.profiles(id,full_name) values(new.id,coalesce(new.raw_user_meta_data->>'full_name','')) on conflict(id) do nothing;
  return new;
end;$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users for each row execute function public.handle_new_user();

create or replace function public.is_admin() returns boolean
language sql stable security definer set search_path=public as $$
  select exists(select 1 from public.admin_users where user_id=auth.uid());
$$;
revoke all on function public.is_admin() from anon;
grant execute on function public.is_admin() to authenticated;

create or replace function public.prevent_role_escalation() returns trigger
language plpgsql security definer set search_path=public as $$
begin
  if new.role is distinct from old.role and not public.is_admin() then new.role:=old.role; end if;
  return new;
end;$$;
drop trigger if exists protect_profile_role on public.profiles;
create trigger protect_profile_role before update on public.profiles for each row execute function public.prevent_role_escalation();

alter table public.profiles enable row level security;
alter table public.categories enable row level security;
alter table public.preachers enable row level security;
alter table public.sermons enable row level security;
alter table public.favorites enable row level security;
alter table public.live_streams enable row level security;
alter table public.admin_users enable row level security;

-- Public reads needed by the app.
drop policy if exists categories_public_read on public.categories;
create policy categories_public_read on public.categories for select using (true);
drop policy if exists preachers_public_read on public.preachers;
create policy preachers_public_read on public.preachers for select using (true);
drop policy if exists sermons_published_read on public.sermons;
create policy sermons_published_read on public.sermons for select using (published=true or public.is_admin());
drop policy if exists live_public_read on public.live_streams;
create policy live_public_read on public.live_streams for select using (is_live=true or public.is_admin());

-- Users can read/update their own profile, but cannot change their role.
drop policy if exists profiles_self_read on public.profiles;
create policy profiles_self_read on public.profiles for select using (auth.uid()=id);
drop policy if exists profiles_self_update on public.profiles;
create policy profiles_self_update on public.profiles for update using (auth.uid()=id) with check (auth.uid()=id);

-- Favorites belong to the signed-in user.
drop policy if exists favorites_self_all on public.favorites;
create policy favorites_self_all on public.favorites for all using (auth.uid()=user_id) with check (auth.uid()=user_id);

-- Administrators can manage content.
drop policy if exists sermons_admin_write on public.sermons;
create policy sermons_admin_write on public.sermons for all using (public.is_admin()) with check (public.is_admin());
drop policy if exists categories_admin_write on public.categories;
create policy categories_admin_write on public.categories for all using (public.is_admin()) with check (public.is_admin());
drop policy if exists preachers_admin_write on public.preachers;
create policy preachers_admin_write on public.preachers for all using (public.is_admin()) with check (public.is_admin());
drop policy if exists live_admin_write on public.live_streams;
create policy live_admin_write on public.live_streams for all using (public.is_admin()) with check (public.is_admin());

revoke all on public.admin_users from anon,authenticated;

-- AFTER creating the admin user in Authentication, run:
-- insert into public.admin_users(user_id)
-- select id from auth.users where email='YOUR_ADMIN_EMAIL'
-- on conflict do nothing;

create index if not exists sermons_published_created_idx on public.sermons(published,created_at desc);
create index if not exists sermons_category_idx on public.sermons(category_id);
create index if not exists sermons_preacher_idx on public.sermons(preacher_id);
