alter table public.profiles
add column if not exists privacy_policy_accepted boolean not null default false,
add column if not exists privacy_policy_accepted_at timestamptz null,
add column if not exists privacy_policy_version text null;
