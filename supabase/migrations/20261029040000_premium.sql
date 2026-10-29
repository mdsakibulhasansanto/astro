-- Premium subscription status on profiles. Set by the verify-purchase
-- function (Google Play) or by an admin; users cannot change it themselves.
alter table public.profiles
  add column if not exists is_premium boolean not null default false,
  add column if not exists premium_until timestamptz,
  add column if not exists premium_product text;

-- Extend the role guard: role and premium fields change only through an
-- admin, the SQL editor or the service role.
create or replace function public.protect_profile_role()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is not null and not public.is_admin() and (
       new.role is distinct from old.role
    or new.is_premium is distinct from old.is_premium
    or new.premium_until is distinct from old.premium_until
    or new.premium_product is distinct from old.premium_product
  ) then
    raise exception 'Only admins can change roles or premium status';
  end if;
  return new;
end;
$$;

-- Premium count for the admin dashboard.
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
    'premium_users', (select count(*) from profiles
                      where is_premium and (premium_until is null or premium_until > now())),
    'birth_profiles', (select count(*) from birth_profiles),
    'charts', (select count(*) from astrology_results),
    'homes', (select count(*) from homes),
    'rooms', (select count(*) from rooms),
    'furniture', (select count(*) from furniture),
    'designs', (select count(*) from room_designs),
    'daily_readings', (select count(*) from daily_readings),
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
