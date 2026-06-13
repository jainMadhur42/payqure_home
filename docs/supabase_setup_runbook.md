# Supabase Setup Runbook

## 1. Apply Database Migration

For a new production Supabase project, run the single bootstrap file:

```text
supabase/migrations/202606130001_create_payqure_home_production_schema.sql
```

Run the complete file once in the Supabase SQL editor or migration pipeline.
It creates the final schema, indexes, functions, Row Level Security policies,
privacy fields, OTP request limits, payment allocation fields, and optimized
monthly JSON logs.

After applying it, verify:

```sql
select public.ledger_schema_version();
```

Expected result:

```text
5
```

## 2. Configure Auth

In Supabase Auth settings:

- Enable email/password sign-in.
- Enable email confirmations.
- Keep phone verification disabled unless you intentionally add it later.
- Add the app redirect URLs for email confirmation and password recovery.
- Configure custom SMTP before testing with addresses that are not Supabase
  organization members. The built-in sender is restricted and heavily
  rate-limited.

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

The Flutter app uses typed six-digit OTPs rather than confirmation links.
Update both templates to include the token:

**Confirm signup**

```html
<h2>Verify your Payqure Home account</h2>
<p>Your verification code is:</p>
<h1>{{ .Token }}</h1>
<p>This code expires shortly and can only be used once.</p>
```

**Reset password**

```html
<h2>Reset your Payqure Home password</h2>
<p>Your recovery code is:</p>
<h1>{{ .Token }}</h1>
<p>This code expires shortly and can only be used once.</p>
```

Do not leave these templates using only `{{ .ConfirmationURL }}` because the
app expects the user to enter the token.

## 4. Run App With Supabase

Normal VS Code and `flutter run` debug builds use the configured debug
Supabase target automatically:

```bash
flutter run
```

Store release builds use the configured release Supabase target automatically:

```bash
flutter build appbundle --release
flutter build ipa --release
```

Override either environment when needed:

```bash
flutter run \
  --dart-define=APP_ENV=debug \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=YOUR_PUBLISHABLE_KEY
```

Environment defaults and telemetry behavior are centralized in
`lib/core/config/app_config.dart`.

Debug/profile builds use the non-production Supabase project. Release builds
use the production Supabase project.

## 5. Smoke Test

1. Register with name, email, phone, and password.
2. Confirm that `public.profiles` contains the user row.
3. Confirm email from the Supabase email.
4. Return to the app and tap `I Verified Email`.
5. Confirm the dashboard opens and demo ledger data is created locally.
6. Create or edit ledger data and confirm Supabase rows are created when online.

## 6. Troubleshooting

- If ledger sync fails with a schema message, verify the bootstrap completed
  successfully and `public.ledger_schema_version()` returns `5`.
- If phone login fails, confirm the phone is stored normalized in E.164 format in `public.profiles`.
- If email verification does not route back into the app, check Supabase redirect URLs and platform deep-link configuration.
