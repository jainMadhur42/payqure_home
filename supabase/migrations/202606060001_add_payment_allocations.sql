alter table public.payment_transactions
add column if not exists current_month_amount_cents integer not null default 0,
add column if not exists previous_balance_amount_cents integer not null default 0,
add column if not exists advance_amount_cents integer not null default 0;

update public.app_schema_versions
set version = 3,
    applied_at = now()
where id = 'ledger';
