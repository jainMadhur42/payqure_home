# OTP Request Support Process

Email-confirmation and password-recovery OTP requests are limited to three per
email and purpose. The fourth request blocks further OTP sends until support
reviews the account.

## Support Review

1. Confirm the requester controls the registered email.
2. Review recent Supabase Auth logs for suspicious activity.
3. Reset only the requested purpose:

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
