-- ProAIcademy schema: catalogue content tables + user profiles.
-- Applied to project yiwgyovzohcwvqpwmesk.

-- ============ helper: keep updated_at fresh ============
create or replace function public.set_updated_at()
returns trigger language plpgsql set search_path = '' as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

-- ============ COURSES ============
create table if not exists public.courses (
  id           text primary key,
  cat          text not null,
  level        text not null,
  lessons      int  not null default 0,
  hours        numeric not null default 0,
  rating       numeric not null default 0,
  reviews      int  not null default 0,
  students     int  not null default 0,
  price        bigint not null default 0,
  old_price    bigint not null default 0,
  icon         text,
  grad         text,
  instructor   text,
  tag_key      text default '',
  title        jsonb not null default '{}'::jsonb,   -- {en, id}
  description  jsonb not null default '{}'::jsonb,   -- {en, id}
  sort_order   int  not null default 0,
  is_published boolean not null default true,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);

-- ============ EBOOKS ============
create table if not exists public.ebooks (
  id           text primary key,
  cat          text not null,
  price        bigint not null default 0,
  old_price    bigint not null default 0,
  icon         text,
  grad         text,
  pages        int  not null default 0,
  rating       numeric not null default 0,
  downloads    int  not null default 0,
  title        jsonb not null default '{}'::jsonb,
  description  jsonb not null default '{}'::jsonb,
  sort_order   int  not null default 0,
  is_published boolean not null default true,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);

-- ============ CONSULTING PACKAGES ============
create table if not exists public.consulting_packages (
  id           text primary key,
  price        bigint not null default 0,
  unit_key     text not null default 'custom',
  featured     boolean not null default false,
  icon         text,
  name         jsonb not null default '{}'::jsonb,     -- {en, id}
  tagline      jsonb not null default '{}'::jsonb,     -- {en, id}
  features     jsonb not null default '{}'::jsonb,     -- {en:[], id:[]}
  sort_order   int  not null default 0,
  is_published boolean not null default true,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);

-- ============ TESTIMONIALS ============
create table if not exists public.testimonials (
  id           text primary key,
  name         text not null,
  role         jsonb not null default '{}'::jsonb,     -- {en, id}
  avatar       text,
  grad         text,
  quote        jsonb not null default '{}'::jsonb,     -- {en, id}
  sort_order   int  not null default 0,
  is_published boolean not null default true,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);

-- ============ FAQS ============
create table if not exists public.faqs (
  id           text primary key,
  question     jsonb not null default '{}'::jsonb,     -- {en, id}
  answer       jsonb not null default '{}'::jsonb,     -- {en, id}
  sort_order   int  not null default 0,
  is_published boolean not null default true,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);

-- updated_at triggers for content tables
do $$
declare t text;
begin
  foreach t in array array['courses','ebooks','consulting_packages','testimonials','faqs']
  loop
    execute format('drop trigger if exists trg_%1$s_updated on public.%1$s;', t);
    execute format('create trigger trg_%1$s_updated before update on public.%1$s
                    for each row execute function public.set_updated_at();', t);
  end loop;
end $$;

-- ============ PROFILES (linked to auth.users) ============
create table if not exists public.profiles (
  id          uuid primary key references auth.users(id) on delete cascade,
  full_name   text,
  email       text,
  avatar_url  text,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

drop trigger if exists trg_profiles_updated on public.profiles;
create trigger trg_profiles_updated before update on public.profiles
  for each row execute function public.set_updated_at();

-- auto-create a profile row whenever a new auth user signs up
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, full_name, email, avatar_url)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'full_name', new.raw_user_meta_data->>'name'),
    new.email,
    new.raw_user_meta_data->>'avatar_url'
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

-- only the trigger should call this, not the public REST API
revoke execute on function public.handle_new_user() from public, anon, authenticated;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ============ ROW LEVEL SECURITY ============
alter table public.courses             enable row level security;
alter table public.ebooks              enable row level security;
alter table public.consulting_packages enable row level security;
alter table public.testimonials        enable row level security;
alter table public.faqs                enable row level security;
alter table public.profiles            enable row level security;

-- Public (anon + authenticated) may READ published catalogue content.
create policy "Public read published courses"
  on public.courses for select to anon, authenticated using (is_published);
create policy "Public read published ebooks"
  on public.ebooks for select to anon, authenticated using (is_published);
create policy "Public read published consulting"
  on public.consulting_packages for select to anon, authenticated using (is_published);
create policy "Public read published testimonials"
  on public.testimonials for select to anon, authenticated using (is_published);
create policy "Public read published faqs"
  on public.faqs for select to anon, authenticated using (is_published);

-- Writes to content tables are intentionally NOT granted to anon/authenticated.
-- Admins manage content via the Supabase dashboard / service role.

-- Profiles: each user manages only their own row.
create policy "Users read own profile"
  on public.profiles for select to authenticated using (auth.uid() = id);
create policy "Users update own profile"
  on public.profiles for update to authenticated using (auth.uid() = id) with check (auth.uid() = id);
create policy "Users insert own profile"
  on public.profiles for insert to authenticated with check (auth.uid() = id);
