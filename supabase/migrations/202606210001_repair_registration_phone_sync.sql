begin;

-- Email-confirmation signup may return no authenticated client session. Keep
-- profile creation server-side so registration phone data is persisted before
-- the user verifies the email OTP.
create or replace function public.handle_new_auth_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  metadata jsonb := coalesce(new.raw_user_meta_data, '{}'::jsonb);
  profile_phone text := nullif(
    trim(
      coalesce(
        metadata ->> 'phone',
        metadata ->> 'phone_number',
        new.phone
      )
    ),
    ''
  );
  policy_accepted boolean :=
    lower(coalesce(metadata ->> 'privacy_policy_accepted', 'false')) = 'true';
begin
  if profile_phone is null then
    return new;
  end if;

  insert into public.profiles (
    id,
    name,
    email,
    phone,
    email_verified,
    privacy_policy_accepted,
    privacy_policy_accepted_at,
    privacy_policy_version,
    updated_at
  )
  values (
    new.id,
    coalesce(nullif(trim(metadata ->> 'name'), ''), 'Payqure User'),
    coalesce(new.email, metadata ->> 'email', ''),
    profile_phone,
    new.email_confirmed_at is not null,
    policy_accepted,
    nullif(metadata ->> 'privacy_policy_accepted_at', '')::timestamptz,
    nullif(metadata ->> 'privacy_policy_version', ''),
    now()
  )
  on conflict (id) do update
  set name = excluded.name,
      email = excluded.email,
      phone = excluded.phone,
      email_verified = excluded.email_verified,
      privacy_policy_accepted = excluded.privacy_policy_accepted,
      privacy_policy_accepted_at = excluded.privacy_policy_accepted_at,
      privacy_policy_version = excluded.privacy_policy_version,
      updated_at = excluded.updated_at;

  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_auth_user();

-- Repair users created while the trigger was absent or using an older metadata
-- contract. Skip conflicting numbers so this migration never steals a phone
-- already owned by another profile.
insert into public.profiles (
  id,
  name,
  email,
  phone,
  email_verified,
  privacy_policy_accepted,
  privacy_policy_accepted_at,
  privacy_policy_version,
  updated_at
)
select
  users.id,
  coalesce(
    nullif(trim(users.raw_user_meta_data ->> 'name'), ''),
    'Payqure User'
  ),
  coalesce(users.email, users.raw_user_meta_data ->> 'email', ''),
  source.phone,
  users.email_confirmed_at is not null,
  lower(
    coalesce(
      users.raw_user_meta_data ->> 'privacy_policy_accepted',
      'false'
    )
  ) = 'true',
  nullif(
    users.raw_user_meta_data ->> 'privacy_policy_accepted_at',
    ''
  )::timestamptz,
  nullif(users.raw_user_meta_data ->> 'privacy_policy_version', ''),
  now()
from auth.users as users
cross join lateral (
  select nullif(
    trim(
      coalesce(
        users.raw_user_meta_data ->> 'phone',
        users.raw_user_meta_data ->> 'phone_number',
        users.phone
      )
    ),
    ''
  ) as phone
) as source
where source.phone is not null
  and not exists (
    select 1
    from public.profiles as owner
    where owner.phone = source.phone
      and owner.id <> users.id
  )
on conflict (id) do update
set name = excluded.name,
    email = excluded.email,
    phone = excluded.phone,
    email_verified = excluded.email_verified,
    updated_at = excluded.updated_at;

notify pgrst, 'reload schema';

commit;
