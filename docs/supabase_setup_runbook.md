# Supabase Setup Runbook

## 1. Apply Database Migration

Run the SQL in `supabase/migrations/202606030001_create_ledger_schema.sql` in your Supabase project SQL editor or migration pipeline.

After applying it, verify:

```sql
select public.ledger_schema_version();
```

Expected result:

```text
1
```

## 2. Configure Auth

In Supabase Auth settings:

- Enable email/password sign-in.
- Enable email confirmations.
- Keep phone verification disabled unless you intentionally add it later.
- Add the app redirect URLs for email confirmation and password recovery.

Suggested redirect URL placeholders:

```text
payqurehome://auth/callback
io.supabase.flutterquickstart://login-callback/
```

Use the final app scheme/package-specific callback URL once the mobile app identifiers are finalized.

## 3. Email Templates

Configure:

- Confirm signup template.
- Reset password/recovery template.

For OTP-style recovery, include the Supabase token in the email body. The Flutter reset screen expects the user to enter email, OTP, and new password.

## 4. Run App With Supabase

Run with real project values:

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=YOUR_PUBLISHABLE_KEY
```

For this local workspace, use the ignored Supabase define file:

```bash
flutter run --dart-define-from-file=dart_defines/supabase.local.json
```

Without these values, the app runs in local demo auth mode.

## 5. Smoke Test

1. Register with name, email, phone, and password.
2. Confirm that `public.profiles` contains the user row.
3. Confirm email from the Supabase email.
4. Return to the app and tap `I Verified Email`.
5. Confirm the dashboard opens and demo ledger data is created locally.
6. Create or edit ledger data and confirm Supabase rows are created when online.

## 6. Troubleshooting

- If ledger sync fails with a schema message, rerun the migration and verify `public.ledger_schema_version()` returns `1`.
- If phone login fails, confirm the phone is stored normalized in E.164 format in `public.profiles`.
- If email verification does not route back into the app, check Supabase redirect URLs and platform deep-link configuration.
