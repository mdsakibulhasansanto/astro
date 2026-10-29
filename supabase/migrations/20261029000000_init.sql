-- Astro Home schema: users (profiles), birth profiles, astrology results,
-- homes, rooms and furniture. Row-level security keeps each user's data
-- private; admins (profiles.role = 'admin') can read everything.

create extension if not exists pgcrypto;

-- ---------------------------------------------------------------------------
-- Users
-- ---------------------------------------------------------------------------
create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  name text,
  email text,
  role text not null default 'user' check (role in ('user', 'admin')),
  created_at timestamptz not null default now()
);

-- Creates the profile row when someone signs up.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, name, email)
  values (new.id, new.raw_user_meta_data ->> 'name', new.email);
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- True when the caller is an admin. Security definer so policies on
-- profiles can call it without recursing.
create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.profiles where id = auth.uid() and role = 'admin'
  );
$$;

-- Only admins may change a role (including their own). The SQL editor and
-- service role have no auth.uid(), so the first admin can be set there.
create or replace function public.protect_profile_role()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.role is distinct from old.role
     and auth.uid() is not null
     and not public.is_admin() then
    raise exception 'Only admins can change roles';
  end if;
  return new;
end;
$$;

create trigger protect_profile_role
  before update on public.profiles
  for each row execute function public.protect_profile_role();

-- ---------------------------------------------------------------------------
-- Birth profile (one per user) and calculated chart
-- ---------------------------------------------------------------------------
create table public.birth_profiles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null unique references public.profiles (id) on delete cascade,
  name text not null default '',
  birth_date date not null,
  birth_time time,                      -- null when unknown
  birth_place text not null,
  latitude double precision not null check (latitude between -90 and 90),
  longitude double precision not null check (longitude between -180 and 180),
  timezone text not null,               -- IANA id, e.g. Asia/Dhaka
  kua_basis text not null default 'female' check (kua_basis in ('female', 'male')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Written only by the astrology-chart Edge Function (service role), so a
-- chart in the database always comes from the calculation engine.
create table public.astrology_results (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null unique references public.birth_profiles (id) on delete cascade,
  sun_sign text not null,
  moon_sign text not null,
  ascendant text,
  ascendant_longitude double precision,
  planet_data jsonb not null,
  houses jsonb not null default '[]'::jsonb,
  element_balance jsonb not null,
  dominant_element text not null,
  weakest_element text not null,
  calculated_at timestamptz not null default now()
);

-- ---------------------------------------------------------------------------
-- Home, rooms, furniture
-- ---------------------------------------------------------------------------
create table public.homes (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  home_name text not null,
  created_at timestamptz not null default now()
);

create table public.rooms (
  id uuid primary key default gen_random_uuid(),
  home_id uuid not null references public.homes (id) on delete cascade,
  room_name text not null,
  width double precision not null check (width > 0),     -- along the door wall
  height double precision not null check (height > 0),   -- door to far wall
  unit text not null default 'ft' check (unit in ('ft', 'm')),
  direction text not null default 'N'
    check (direction in ('N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW')),
  door_position text not null default 'center'
    check (door_position in ('left', 'center', 'right')),
  window_position text not null default 'top'
    check (window_position in ('top', 'left', 'right', 'none')),
  bagua_method text not null default 'door' check (bagua_method in ('door', 'compass')),
  created_at timestamptz not null default now()
);

-- Positions and sizes are relative to the room (0–1).
create table public.furniture (
  id uuid primary key default gen_random_uuid(),
  room_id uuid not null references public.rooms (id) on delete cascade,
  type text not null,
  label text not null,
  x_position double precision not null check (x_position between 0 and 1),
  y_position double precision not null check (y_position between 0 and 1),
  width double precision not null check (width > 0 and width <= 1),
  height double precision not null check (height > 0 and height <= 1),
  rotation integer not null default 0 check (rotation in (0, 90, 180, 270)),
  created_at timestamptz not null default now()
);

create index on public.homes (user_id);
create index on public.rooms (home_id);
create index on public.furniture (room_id);

create or replace function public.touch_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger birth_profiles_updated
  before update on public.birth_profiles
  for each row execute function public.touch_updated_at();

-- ---------------------------------------------------------------------------
-- Row-level security
-- ---------------------------------------------------------------------------
alter table public.profiles enable row level security;
alter table public.birth_profiles enable row level security;
alter table public.astrology_results enable row level security;
alter table public.homes enable row level security;
alter table public.rooms enable row level security;
alter table public.furniture enable row level security;

-- profiles
create policy "read own profile or admin" on public.profiles
  for select using (id = auth.uid() or public.is_admin());
create policy "update own profile or admin" on public.profiles
  for update using (id = auth.uid() or public.is_admin());

-- birth_profiles
create policy "read own birth profile or admin" on public.birth_profiles
  for select using (user_id = auth.uid() or public.is_admin());
create policy "insert own birth profile" on public.birth_profiles
  for insert with check (user_id = auth.uid());
create policy "update own birth profile" on public.birth_profiles
  for update using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "delete own birth profile" on public.birth_profiles
  for delete using (user_id = auth.uid());

-- astrology_results: read-only for users; writes come from the Edge Function.
create policy "read own chart or admin" on public.astrology_results
  for select using (
    public.is_admin() or exists (
      select 1 from public.birth_profiles b
      where b.id = profile_id and b.user_id = auth.uid()
    )
  );

-- homes
create policy "read own homes or admin" on public.homes
  for select using (user_id = auth.uid() or public.is_admin());
create policy "write own homes" on public.homes
  for all using (user_id = auth.uid()) with check (user_id = auth.uid());

-- rooms
create policy "read own rooms or admin" on public.rooms
  for select using (
    public.is_admin() or exists (
      select 1 from public.homes h where h.id = home_id and h.user_id = auth.uid()
    )
  );
create policy "write own rooms" on public.rooms
  for all using (
    exists (select 1 from public.homes h where h.id = home_id and h.user_id = auth.uid())
  ) with check (
    exists (select 1 from public.homes h where h.id = home_id and h.user_id = auth.uid())
  );

-- furniture
create policy "read own furniture or admin" on public.furniture
  for select using (
    public.is_admin() or exists (
      select 1 from public.rooms r join public.homes h on h.id = r.home_id
      where r.id = room_id and h.user_id = auth.uid()
    )
  );
create policy "write own furniture" on public.furniture
  for all using (
    exists (
      select 1 from public.rooms r join public.homes h on h.id = r.home_id
      where r.id = room_id and h.user_id = auth.uid()
    )
  ) with check (
    exists (
      select 1 from public.rooms r join public.homes h on h.id = r.home_id
      where r.id = room_id and h.user_id = auth.uid()
    )
  );

-- ---------------------------------------------------------------------------
-- Data API access. Explicit so the app works even when new tables are not
-- exposed automatically. Row-level security above still limits every row.
-- ---------------------------------------------------------------------------
grant usage on schema public to anon, authenticated, service_role;
grant select, update on public.profiles to authenticated;
grant select, insert, update, delete on
  public.birth_profiles, public.homes, public.rooms, public.furniture
  to authenticated;
grant select on public.astrology_results to authenticated;
grant all on all tables in schema public to service_role;

-- ---------------------------------------------------------------------------
-- Admin dashboard summary (admins only)
-- ---------------------------------------------------------------------------
create or replace function public.admin_stats()
returns json
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  if not public.is_admin() then
    raise exception 'Admins only';
  end if;
  return json_build_object(
    'users', (select count(*) from profiles),
    'birth_profiles', (select count(*) from birth_profiles),
    'charts', (select count(*) from astrology_results),
    'homes', (select count(*) from homes),
    'rooms', (select count(*) from rooms),
    'furniture', (select count(*) from furniture),
    'new_users_7d', (select count(*) from profiles where created_at > now() - interval '7 days'),
    'sun_signs', coalesce((
      select json_object_agg(sun_sign, n) from (
        select sun_sign, count(*) n from astrology_results group by sun_sign
      ) s), '{}'::json),
    'furniture_types', coalesce((
      select json_object_agg(type, n) from (
        select type, count(*) n from furniture group by type
      ) f), '{}'::json),
    'room_directions', coalesce((
      select json_object_agg(direction, n) from (
        select direction, count(*) n from rooms group by direction
      ) d), '{}'::json)
  );
end;
$$;

revoke all on function public.admin_stats() from public, anon;
grant execute on function public.admin_stats() to authenticated;

-- ---------------------------------------------------------------------------
-- Make the first admin (run once in the SQL editor, with your email):
--   update public.profiles set role = 'admin' where email = 'you@example.com';
-- ---------------------------------------------------------------------------
