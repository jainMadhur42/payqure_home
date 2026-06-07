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

revoke all on table public.auth_otp_request_limits from anon;
revoke all on table public.auth_otp_request_limits from authenticated;

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

    return query select false, current_record.request_count, true;
    return;
  end if;

  update public.auth_otp_request_limits
  set request_count = auth_otp_request_limits.request_count + 1,
      last_requested_at = now()
  where identifier = normalized_identifier
    and purpose = request_purpose
  returning auth_otp_request_limits.request_count
  into current_record.request_count;

  return query select true, current_record.request_count, false;
end;
$$;

revoke all on function public.claim_auth_otp_request(text, text) from public;
grant execute on function public.claim_auth_otp_request(text, text) to anon;
grant execute on function public.claim_auth_otp_request(text, text) to authenticated;

comment on table public.auth_otp_request_limits is
'Private support-managed OTP request counters. To unblock after review, reset request_count to 0 and blocked to false for the requested identifier and purpose.';

update public.app_schema_versions
set version = 4,
    applied_at = now()
where id = 'ledger';
