-- Planner upgrades: furniture colour, saved designs and recommendation
-- history.

alter table public.furniture
  add column if not exists color text check (color is null or color ~ '^#[0-9A-Fa-f]{6}$');

-- A saved snapshot of a room's furniture layout ("design").
create table if not exists public.room_designs (
  id uuid primary key default gen_random_uuid(),
  room_id uuid not null references public.rooms (id) on delete cascade,
  name text not null,
  -- Same shape as furniture rows: type, label, x/y, width/height, rotation, color.
  items jsonb not null default '[]'::jsonb,
  -- 'saved' by the user, or 'suggested' when created from the recommendations.
  kind text not null default 'saved' check (kind in ('saved', 'suggested')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Recommendation results the user chose to keep.
create table if not exists public.recommendation_history (
  id uuid primary key default gen_random_uuid(),
  room_id uuid not null references public.rooms (id) on delete cascade,
  summary text not null,
  improvement_count integer not null default 0,
  piece_count integer not null default 0,
  -- Placement advice: furniture, current zone, verdict, suggested zone, rule.
  placements jsonb not null default '[]'::jsonb,
  created_at timestamptz not null default now()
);

create index if not exists room_designs_room_idx on public.room_designs (room_id);
create index if not exists recommendation_history_room_idx on public.recommendation_history (room_id);

drop trigger if exists room_designs_updated on public.room_designs;
create trigger room_designs_updated
  before update on public.room_designs
  for each row execute function public.touch_updated_at();

alter table public.room_designs enable row level security;
alter table public.recommendation_history enable row level security;

-- Owner = the user who owns the room's home.
create or replace function public.owns_room(rid uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from rooms r join homes h on h.id = r.home_id
    where r.id = rid and h.user_id = auth.uid()
  );
$$;

drop policy if exists "read own designs or admin" on public.room_designs;
create policy "read own designs or admin" on public.room_designs
  for select using (public.owns_room(room_id) or public.is_admin());
drop policy if exists "write own designs" on public.room_designs;
create policy "write own designs" on public.room_designs
  for all using (public.owns_room(room_id)) with check (public.owns_room(room_id));

drop policy if exists "read own history or admin" on public.recommendation_history;
create policy "read own history or admin" on public.recommendation_history
  for select using (public.owns_room(room_id) or public.is_admin());
drop policy if exists "write own history" on public.recommendation_history;
create policy "write own history" on public.recommendation_history
  for all using (public.owns_room(room_id)) with check (public.owns_room(room_id));

grant select, insert, update, delete on public.room_designs, public.recommendation_history
  to authenticated;
grant all on public.room_designs, public.recommendation_history to service_role;
