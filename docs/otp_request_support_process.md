# OTP Request Support Process

Email-confirmation and password-recovery OTP requests are limited to three per
email and purpose in a fixed 60-minute window. The fourth request is rejected.
When the window expires, the next request automatically resets the counter.

## Optional Support Reset

Normally no support action is required. For a verified exceptional case,
support can reset only the requested purpose:

```sql
update public.auth_otp_request_limits
set request_count = 0,
    blocked = false,
    blocked_at = null,
    reviewed_at = now(),
    reviewed_by = 'support-agent'
where identifier = lower(trim('customer@example.com'))
  and purpose = 'password_reset';
```

Use `purpose = 'signup'` for email-confirmation requests.

## Production Security

Enable Supabase CAPTCHA protection for signup and password-reset forms before
release. The OTP counter RPC is callable before authentication by necessity;
CAPTCHA reduces the risk of someone exhausting another user's request limit.
