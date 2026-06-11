create table if not exists public.service_month_logs (
  id text primary key,
  service_id text not null references public.services(id) on delete cascade,
  month_key text not null,
  schema_version integer not null default 1,
  entries_json text not null default '{"schemaVersion":1,"overrides":{}}',
  updated_at timestamptz not null default now(),
  is_deleted boolean not null default false,
  constraint service_month_logs_json_valid check (jsonb_typeof(entries_json::jsonb) = 'object')
);

create index if not exists service_month_logs_service_month_idx
on public.service_month_logs (service_id, month_key);

create index if not exists service_month_logs_month_idx
on public.service_month_logs (month_key);

insert into public.service_month_logs (
  id,
  service_id,
  month_key,
  schema_version,
  entries_json,
  updated_at,
  is_deleted
)
select
  service_id || ':' || month_key as id,
  service_id,
  month_key,
  1 as schema_version,
  jsonb_build_object(
    'schemaVersion', 1,
    'overrides', jsonb_object_agg(
      day::text,
      jsonb_build_object(
        'id', id,
        'status', status,
        'quantity', quantity,
        'unit', unit,
        'rateCents', rate_cents,
        'amountCents', amount_cents,
        'note', note,
        'updatedAt', updated_at
      )
    )
  )::text as entries_json,
  max(updated_at) as updated_at,
  false as is_deleted
from public.service_entries
where is_deleted = false
group by service_id, month_key
on conflict (id) do nothing;

alter table public.service_month_logs enable row level security;

drop policy if exists "month-logs-own-service" on public.service_month_logs;
create policy "month-logs-own-service"
on public.service_month_logs
for all
using (
  exists (
    select 1 from public.services
    where services.id = service_month_logs.service_id
      and services.user_id = auth.uid()
  )
)
with check (
  exists (
    select 1 from public.services
    where services.id = service_month_logs.service_id
      and services.user_id = auth.uid()
  )
);

update public.app_schema_versions
set version = 5,
    applied_at = now()
where id = 'ledger';
