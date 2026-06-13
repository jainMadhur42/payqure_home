# Payqure Home

Daily Service Ledger is a Flutter app for tracking household services, daily entries, advances, monthly bills, and PDF statements.

## Architecture

- Flutter UI with reusable theme/common widgets.
- Clean-ish feature split under `lib/features/ledger`.
- Drift/SQLite for local offline data.
- Supabase Auth and Postgres for production auth/profile/ledger sync.
- Supabase Auth session persistence across app restarts.

## Supabase Setup

See [docs/supabase_setup_runbook.md](docs/supabase_setup_runbook.md).

## Run

Run from VS Code or the terminal with the configured debug Supabase target:

```bash
flutter run
```

Release builds automatically use their configured Supabase project and enable
Firebase Analytics and Crashlytics:

```bash
flutter build appbundle --release
flutter build ipa --release
```

Android release builds also require Play Store upload-key configuration. Copy
`android/key.properties.example` to the ignored `android/key.properties` file
and provide the real keystore path and credentials. Release builds fail fast
when signing is missing instead of creating a debug-signed store artifact.

Build-mode defaults are centralized in
`lib/core/config/app_config.dart`:

- Debug/profile: non-production Supabase, verbose diagnostics, and telemetry
  off.
- Release: production Supabase, verbose diagnostics off, and telemetry on.

Override configuration for CI or a temporary environment:

```bash
flutter run \
  --dart-define=APP_ENV=debug \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=YOUR_PUBLISHABLE_KEY
```

Supported optional overrides:

- `APP_ENV=debug|release`
- `SUPABASE_URL`
- `SUPABASE_PUBLISHABLE_KEY`
- `ANALYTICS_ENABLED=true|false`
- `CRASHLYTICS_ENABLED=true|false`
- `VERBOSE_LOGGING_ENABLED=true|false`

## Verify

```bash
dart run build_runner build --delete-conflicting-outputs
dart format lib test
flutter analyze
flutter test
```
