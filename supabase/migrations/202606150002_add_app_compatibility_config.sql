begin;

create table if not exists public.app_compatibility_config (
  id text primary key,
  minimum_supported_schema_version integer not null,
  minimum_app_version text not null,
  latest_app_version text not null,
  updated_at timestamptz not null default now()
);

-- app_schema_versions is the single source of truth for the installed schema.
alter table public.app_compatibility_config
  drop column if exists current_schema_version cascade;

insert into public.app_compatibility_config (
  id,
  minimum_supported_schema_version,
  minimum_app_version,
  latest_app_version
)
values ('mobile', 3, '1.2.0', '1.6.0')
on conflict (id) do update
set minimum_supported_schema_version =
      excluded.minimum_supported_schema_version,
    minimum_app_version = excluded.minimum_app_version,
    latest_app_version = excluded.latest_app_version,
    updated_at = now();

insert into public.app_schema_versions (id, version)
values ('ledger', 6)
on conflict (id) do update
set version = greatest(public.app_schema_versions.version, excluded.version),
    applied_at = now();

create or replace function public.get_app_compatibility_config()
returns jsonb
language sql
stable
security definer
set search_path = public
as $$
  select jsonb_build_object(
    'current_schema_version', public.ledger_schema_version(),
    'minimum_supported_schema_version',
      config.minimum_supported_schema_version,
    'minimum_app_version', config.minimum_app_version,
    'latest_app_version', config.latest_app_version
  )
  from public.app_compatibility_config as config
  where config.id = 'mobile'
$$;

revoke all on function public.get_app_compatibility_config() from public;
grant execute on function public.get_app_compatibility_config() to anon;
grant execute on function public.get_app_compatibility_config()
  to authenticated;

alter table public.app_compatibility_config enable row level security;

notify pgrst, 'reload schema';

commit;
