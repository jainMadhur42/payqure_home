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

create table if not exists public.app_schema_versions (
  id text primary key,
  version integer not null,
  applied_at timestamptz not null default now()
);

insert into public.app_schema_versions (id, version)
values ('ledger', 2)
on conflict (id) do update
set version = excluded.version,
    applied_at = now();

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
  rate_cents integer not null,
  monthly_amount_cents integer not null default 0,
  updated_at timestamptz not null default now(),
  is_deleted boolean not null default false
);

create table if not exists public.service_entries (
  id text primary key,
  service_id text not null references public.services(id) on delete cascade,
  month_key text not null,
  day integer not null check (day between 1 and 31),
  status text not null,
  quantity numeric not null default 0,
  unit text not null default '',
  rate_cents integer not null default 0,
  amount_cents integer not null default 0,
  note text not null default '',
  updated_at timestamptz not null default now(),
  is_deleted boolean not null default false
);

create table if not exists public.advance_payments (
  id text primary key,
  service_id text not null references public.services(id) on delete cascade,
  month_key text not null,
  amount_cents integer not null,
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
  payment_mode text not null check (payment_mode in ('cash', 'upi', 'bank_transfer', 'other')),
  note text not null default '',
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
  status text not null check (status in ('pending', 'paid', 'partiallyPaid', 'overpaid')),
  generated_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  is_deleted boolean not null default false,
  unique(user_id, service_id, month_key)
);

create index if not exists idx_payment_transactions_user_id
on public.payment_transactions(user_id);

create index if not exists idx_payment_transactions_service_month
on public.payment_transactions(service_id, month_key);

create index if not exists idx_payment_transactions_payment_date
on public.payment_transactions(payment_date);

create index if not exists idx_monthly_settlements_user_month
on public.monthly_settlements(user_id, month_key);

create index if not exists idx_monthly_settlements_service_month
on public.monthly_settlements(service_id, month_key);

alter table public.profiles enable row level security;
alter table public.services enable row level security;
alter table public.service_entries enable row level security;
alter table public.advance_payments enable row level security;
alter table public.payment_transactions enable row level security;
alter table public.monthly_settlements enable row level security;

drop policy if exists "profiles-own-rows" on public.profiles;
create policy "profiles-own-rows"
on public.profiles
for all
using (id = auth.uid())
with check (id = auth.uid());

create or replace function public.email_for_phone_login(login_phone text)
returns text
language sql
stable
security definer
set search_path = public
as $$
  select email
  from public.profiles
  where phone = login_phone
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

drop policy if exists "services-own-rows" on public.services;
create policy "services-own-rows"
on public.services
for all
using (user_id = auth.uid())
with check (user_id = auth.uid());

drop policy if exists "entries-own-service" on public.service_entries;
create policy "entries-own-service"
on public.service_entries
for all
using (
  exists (
    select 1 from public.services
    where services.id = service_entries.service_id
      and services.user_id = auth.uid()
  )
)
with check (
  exists (
    select 1 from public.services
    where services.id = service_entries.service_id
      and services.user_id = auth.uid()
  )
);

drop policy if exists "advances-own-service" on public.advance_payments;
create policy "advances-own-service"
on public.advance_payments
for all
using (
  exists (
    select 1 from public.services
    where services.id = advance_payments.service_id
      and services.user_id = auth.uid()
  )
)
with check (
  exists (
    select 1 from public.services
    where services.id = advance_payments.service_id
      and services.user_id = auth.uid()
  )
);

drop policy if exists "payments-own-rows" on public.payment_transactions;
create policy "payments-own-rows"
on public.payment_transactions
for all
using (user_id = auth.uid())
with check (user_id = auth.uid());

drop policy if exists "settlements-own-rows" on public.monthly_settlements;
create policy "settlements-own-rows"
on public.monthly_settlements
for all
using (user_id = auth.uid())
with check (user_id = auth.uid());
