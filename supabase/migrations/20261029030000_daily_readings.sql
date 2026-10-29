-- Daily readings: today's sky compared with the user's birth chart.
-- Written by the daily-reading function as the user (row-level security).
create table if not exists public.daily_readings (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  reading_date date not null,
  -- moon {sign, name, angle, illumination}, planets, transits, retrogrades
  data jsonb not null,
  created_at timestamptz not null default now(),
  unique (user_id, reading_date)
);

alter table public.daily_readings enable row level security;

drop policy if exists "read own readings or admin" on public.daily_readings;
create policy "read own readings or admin" on public.daily_readings
  for select using (user_id = auth.uid() or public.is_admin());
drop policy if exists "write own readings" on public.daily_readings;
create policy "write own readings" on public.daily_readings
  for all using (user_id = auth.uid()) with check (user_id = auth.uid());

grant select, insert, update, delete on public.daily_readings to authenticated;
grant all on public.daily_readings to service_role;
