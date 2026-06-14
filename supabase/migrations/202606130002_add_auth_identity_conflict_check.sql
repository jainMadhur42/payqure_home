begin;

-- Auth signup errors deliberately hide account existence details. This RPC
-- lets the app validate its own email/phone uniqueness rules before requesting
-- an OTP or invoking Auth signup. For authenticated profile edits, auth.uid()
-- is excluded so keeping the current phone remains valid.
create or replace function public.auth_identity_conflicts(
  request_email text,
  request_phone text
)
returns table (
  email_registered boolean,
  phone_registered boolean
)
language sql
stable
security definer
set search_path = public
as $$
  select
    exists (
      select 1
      from auth.users
      where email = lower(trim(request_email))
        and (auth.uid() is null or id <> auth.uid())
    ),
    exists (
      select 1
      from public.profiles
      where phone = trim(request_phone)
        and (auth.uid() is null or id <> auth.uid())
    )
$$;

revoke all on function public.auth_identity_conflicts(text, text) from public;
grant execute on function public.auth_identity_conflicts(text, text) to anon;
grant execute on function public.auth_identity_conflicts(text, text)
  to authenticated;

notify pgrst, 'reload schema';

commit;
