-- Advanced chart data from the astrology-chart function: Midheaven,
-- house system (Placidus), aspects, modality balance and Moon phase.
alter table public.astrology_results
  add column if not exists mc_longitude double precision,
  add column if not exists house_system text,
  add column if not exists aspects jsonb not null default '[]'::jsonb,
  add column if not exists modality_balance jsonb not null default '{}'::jsonb,
  add column if not exists moon_phase jsonb;
