begin;

alter table public.profiles
add column if not exists preferred_currency text not null default 'USD';

update public.profiles
set preferred_currency = case
  when upper(trim(preferred_currency)) ~ '^[A-Z]{3}$'
    then upper(trim(preferred_currency))
  else 'USD'
end
where preferred_currency <> upper(trim(preferred_currency))
   or upper(trim(preferred_currency)) !~ '^[A-Z]{3}$';

alter table public.profiles
drop constraint if exists profiles_preferred_currency_format;

alter table public.profiles
add constraint profiles_preferred_currency_format
check (preferred_currency ~ '^[A-Z]{3}$');

comment on column public.profiles.preferred_currency is
'User-selected ISO 4217 currency code restored across logout and devices.';

insert into public.app_schema_versions (id, version)
values ('ledger', 8)
on conflict (id) do update
set version = greatest(public.app_schema_versions.version, excluded.version),
    applied_at = now();

notify pgrst, 'reload schema';

commit;
