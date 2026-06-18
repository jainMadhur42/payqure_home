begin;

alter table public.auth_otp_request_limits
add column if not exists window_started_at timestamptz null;

update public.auth_otp_request_limits
set window_started_at = coalesce(last_requested_at, blocked_at, now())
where request_count > 0
  and window_started_at is null;

-- PostgreSQL does not allow CREATE OR REPLACE to change OUT parameters.
-- Keep the same input signature so older app versions can call this RPC.
-- The transaction makes the drop/recreate atomic for concurrent clients.
drop function if exists public.claim_auth_otp_request(text, text);

create or replace function public.claim_auth_otp_request(
  request_identifier text,
  request_purpose text
)
returns table (
  allowed boolean,
  request_count integer,
  blocked boolean,
  window_resets_at timestamptz
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

  if current_record.window_started_at is null
    or current_record.window_started_at <= now() - interval '60 minutes' then
    update public.auth_otp_request_limits
    set request_count = 0,
        blocked = false,
        blocked_at = null,
        last_requested_at = null,
        window_started_at = now()
    where identifier = normalized_identifier
      and purpose = request_purpose
    returning *
    into current_record;
  end if;

  if current_record.request_count >= 3 then
    update public.auth_otp_request_limits
    set blocked = true,
        blocked_at = coalesce(blocked_at, now())
    where identifier = normalized_identifier
      and purpose = request_purpose
    returning *
    into current_record;

    return query
    select
      false,
      current_record.request_count,
      true,
      current_record.window_started_at + interval '60 minutes';
    return;
  end if;

  update public.auth_otp_request_limits
  set request_count = auth_otp_request_limits.request_count + 1,
      last_requested_at = now(),
      window_started_at = coalesce(
        auth_otp_request_limits.window_started_at,
        now()
      ),
      blocked = auth_otp_request_limits.request_count + 1 >= 3,
      blocked_at = case
        when auth_otp_request_limits.request_count + 1 >= 3 then now()
        else null
      end
  where identifier = normalized_identifier
    and purpose = request_purpose
  returning *
  into current_record;

  return query
  select
    true,
    current_record.request_count,
    current_record.blocked,
    current_record.window_started_at + interval '60 minutes';
end;
$$;

revoke all on function public.claim_auth_otp_request(text, text) from public;
grant execute on function public.claim_auth_otp_request(text, text) to anon;
grant execute on function public.claim_auth_otp_request(text, text)
  to authenticated;

comment on function public.claim_auth_otp_request(text, text) is
'Claims one of three OTP requests in a fixed 60-minute window and returns the current count plus the exact reset time.';

insert into public.app_schema_versions (id, version)
values ('ledger', 7)
on conflict (id) do update
set version = greatest(public.app_schema_versions.version, excluded.version),
    applied_at = now();

notify pgrst, 'reload schema';

commit;
