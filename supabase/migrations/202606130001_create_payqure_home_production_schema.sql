begin;

-- Payqure Home production bootstrap schema.
-- Run this file once in a new Supabase project.

create table if not exists public.app_schema_versions (
  id text primary key,
  version integer not null,
  applied_at timestamptz not null default now()
);

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  name text not null,
  email text not null,
  phone text not null unique,
  email_verified boolean not null default false,
  privacy_policy_accepted boolean not null default false,
  privacy_policy_accepted_at timestamptz null,
  privacy_policy_version text null,
  updated_at timestamptz not null default now()
);

-- Email-confirmation signups may not have an authenticated session when the
-- client receives the new auth user. Persist registration metadata from the
-- trusted auth.users insert so name and phone are available immediately.
create or replace function public.handle_new_auth_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  metadata jsonb := coalesce(new.raw_user_meta_data, '{}'::jsonb);
  profile_phone text := nullif(trim(metadata ->> 'phone'), '');
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
    coalesce((metadata ->> 'privacy_policy_accepted')::boolean, false),
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

create table if not exists public.services (
  id text primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  month_key text not null,
  name text not null,
  description text not null,
  icon text not null,
  template_type text not null,
  unit text not null default '',
  default_quantity numeric not null default 1,
  rate_cents integer not null default 0,
  monthly_amount_cents integer not null default 0,
  updated_at timestamptz not null default now(),
  is_deleted boolean not null default false
);

create table if not exists public.service_month_logs (
  id text primary key,
  service_id text not null references public.services(id) on delete cascade,
  month_key text not null,
  schema_version integer not null default 1,
  entries_json text not null default '{"schemaVersion":1,"overrides":{}}',
  updated_at timestamptz not null default now(),
  is_deleted boolean not null default false,
  constraint service_month_logs_service_month_unique
    unique (service_id, month_key),
  constraint service_month_logs_json_valid
    check (jsonb_typeof(entries_json::jsonb) = 'object')
);

create table if not exists public.advance_payments (
  id text primary key,
  service_id text not null references public.services(id) on delete cascade,
  month_key text not null,
  amount_cents integer not null check (amount_cents > 0),
  paid_on timestamptz not null,
  note text not null default '',
  updated_at timestamptz not null default now(),
  is_deleted boolean not null default false
);

create table if not exists public.payment_transactions (
  id text primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  service_id text not null references public.services(id) on delete cascade,
  month_key text not null,
  amount_cents integer not null check (amount_cents > 0),
  payment_date timestamptz not null,
  payment_mode text not null
    check (payment_mode in ('cash', 'upi', 'bank_transfer', 'other')),
  note text not null default '',
  current_month_amount_cents integer not null default 0,
  previous_balance_amount_cents integer not null default 0,
  advance_amount_cents integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  is_deleted boolean not null default false
);

create table if not exists public.monthly_settlements (
  id text primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  service_id text not null references public.services(id) on delete cascade,
  month_key text not null,
  gross_amount_cents integer not null default 0,
  advance_used_cents integer not null default 0,
  previous_carry_forward_cents integer not null default 0,
  previous_advance_cents integer not null default 0,
  payable_amount_cents integer not null default 0,
  paid_amount_cents integer not null default 0,
  remaining_amount_cents integer not null default 0,
  carry_forward_to_next_month_cents integer not null default 0,
  advance_to_next_month_cents integer not null default 0,
  status text not null
    check (status in ('pending', 'paid', 'partiallyPaid', 'overpaid')),
  generated_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  is_deleted boolean not null default false,
  unique (user_id, service_id, month_key)
);

create table if not exists public.auth_otp_request_limits (
  identifier text not null,
  purpose text not null check (purpose in ('signup', 'password_reset')),
  request_count integer not null default 0 check (request_count >= 0),
  blocked boolean not null default false,
  blocked_at timestamptz null,
  last_requested_at timestamptz null,
  reviewed_at timestamptz null,
  reviewed_by text null,
  primary key (identifier, purpose)
);

create index if not exists services_user_id_idx
  on public.services (user_id);
create index if not exists services_user_month_idx
  on public.services (user_id, month_key);
create index if not exists service_month_logs_month_idx
  on public.service_month_logs (month_key);
create index if not exists advance_payments_month_idx
  on public.advance_payments (month_key);
create index if not exists advance_payments_service_month_idx
  on public.advance_payments (service_id, month_key);
create index if not exists payment_transactions_user_id_idx
  on public.payment_transactions (user_id);
create index if not exists payment_transactions_month_idx
  on public.payment_transactions (month_key);
create index if not exists payment_transactions_service_month_idx
  on public.payment_transactions (service_id, month_key);
create index if not exists payment_transactions_payment_date_idx
  on public.payment_transactions (payment_date);
create index if not exists monthly_settlements_user_month_idx
  on public.monthly_settlements (user_id, month_key);
create index if not exists monthly_settlements_service_month_idx
  on public.monthly_settlements (service_id, month_key);

alter table public.profiles enable row level security;
alter table public.services enable row level security;
alter table public.service_month_logs enable row level security;
alter table public.advance_payments enable row level security;
alter table public.payment_transactions enable row level security;
alter table public.monthly_settlements enable row level security;
alter table public.auth_otp_request_limits enable row level security;

drop policy if exists "profiles-own-rows" on public.profiles;
create policy "profiles-own-rows"
on public.profiles
for all
using (id = auth.uid())
with check (id = auth.uid());

drop policy if exists "services-own-rows" on public.services;
create policy "services-own-rows"
on public.services
for all
using (user_id = auth.uid())
with check (user_id = auth.uid());

drop policy if exists "month-logs-own-service" on public.service_month_logs;
create policy "month-logs-own-service"
on public.service_month_logs
for all
using (
  exists (
    select 1
    from public.services
    where services.id = service_month_logs.service_id
      and services.user_id = auth.uid()
  )
)
with check (
  exists (
    select 1
    from public.services
    where services.id = service_month_logs.service_id
      and services.user_id = auth.uid()
  )
);

drop policy if exists "advances-own-service" on public.advance_payments;
create policy "advances-own-service"
on public.advance_payments
for all
using (
  exists (
    select 1
    from public.services
    where services.id = advance_payments.service_id
      and services.user_id = auth.uid()
  )
)
with check (
  exists (
    select 1
    from public.services
    where services.id = advance_payments.service_id
      and services.user_id = auth.uid()
  )
);

drop policy if exists "payments-own-rows" on public.payment_transactions;
create policy "payments-own-rows"
on public.payment_transactions
for all
using (user_id = auth.uid())
with check (
  user_id = auth.uid()
  and exists (
    select 1
    from public.services
    where services.id = payment_transactions.service_id
      and services.user_id = auth.uid()
  )
);

drop policy if exists "settlements-own-rows" on public.monthly_settlements;
create policy "settlements-own-rows"
on public.monthly_settlements
for all
using (user_id = auth.uid())
with check (
  user_id = auth.uid()
  and exists (
    select 1
    from public.services
    where services.id = monthly_settlements.service_id
      and services.user_id = auth.uid()
  )
);

-- The app reads account email from a normalized phone number when the user
-- chooses phone login. It returns at most one profile email.
create or replace function public.email_for_phone_login(login_phone text)
returns text
language sql
stable
security definer
set search_path = public
as $$
  select email
  from public.profiles
  where phone = trim(login_phone)
  limit 1
$$;

revoke all on function public.email_for_phone_login(text) from public;
grant execute on function public.email_for_phone_login(text) to anon;
grant execute on function public.email_for_phone_login(text) to authenticated;

create or replace function public.ledger_schema_version()
returns integer
language sql
stable
security definer
set search_path = public
as $$
  select version
  from public.app_schema_versions
  where id = 'ledger'
$$;

revoke all on function public.ledger_schema_version() from public;
grant execute on function public.ledger_schema_version() to anon;
grant execute on function public.ledger_schema_version() to authenticated;

create or replace function public.claim_auth_otp_request(
  request_identifier text,
  request_purpose text
)
returns table (
  allowed boolean,
  request_count integer,
  blocked boolean
)
language plpgsql
security definer
set search_path = public
as $$
declare
  normalized_identifier text := lower(trim(request_identifier));
  current_record public.auth_otp_request_limits%rowtype;
begin
  if normalized_identifier = '' then
    raise exception 'A valid email is required.';
  end if;

  if request_purpose not in ('signup', 'password_reset') then
    raise exception 'Unsupported OTP request purpose.';
  end if;

  insert into public.auth_otp_request_limits (
    identifier,
    purpose,
    request_count
  )
  values (
    normalized_identifier,
    request_purpose,
    0
  )
  on conflict (identifier, purpose) do nothing;

  select *
  into current_record
  from public.auth_otp_request_limits
  where identifier = normalized_identifier
    and purpose = request_purpose
  for update;

  if current_record.blocked or current_record.request_count >= 3 then
    update public.auth_otp_request_limits
    set blocked = true,
        blocked_at = coalesce(blocked_at, now())
    where identifier = normalized_identifier
      and purpose = request_purpose;

    return query
    select false, current_record.request_count, true;
    return;
  end if;

  update public.auth_otp_request_limits
  set request_count = auth_otp_request_limits.request_count + 1,
      last_requested_at = now()
  where identifier = normalized_identifier
    and purpose = request_purpose
  returning auth_otp_request_limits.request_count
  into current_record.request_count;

  return query
  select true, current_record.request_count, false;
end;
$$;

revoke all on function public.claim_auth_otp_request(text, text) from public;
grant execute on function public.claim_auth_otp_request(text, text) to anon;
grant execute on function public.claim_auth_otp_request(text, text)
  to authenticated;

revoke all on table public.auth_otp_request_limits from anon;
revoke all on table public.auth_otp_request_limits from authenticated;

comment on table public.auth_otp_request_limits is
'Private support-managed OTP request counters. To unblock after review, reset request_count to 0 and blocked to false for the requested identifier and purpose.';

insert into public.app_schema_versions (id, version)
values ('ledger', 5)
on conflict (id) do update
set version = excluded.version,
    applied_at = now();

commit;
