begin;

-- Additive, nullable column: existing rows keep NULL and existing clients keep
-- working unchanged. The value is populated on the user's next sign-in / app
-- launch after they update to a client that records it.
alter table public.profiles
add column if not exists os text;

comment on column public.profiles.os is
'Client OS and version captured on the user''s most recent sign-in / app launch.';

notify pgrst, 'reload schema';

commit;
