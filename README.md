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

Run with the configured Supabase project:

```bash
flutter run
```

Override Supabase for another environment:

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=YOUR_PUBLISHABLE_KEY
```

For this local workspace, Supabase credentials are available in
`dart_defines/supabase.local.json`:

```bash
flutter run --dart-define-from-file=dart_defines/supabase.local.json
```

## Verify

```bash
dart run build_runner build --delete-conflicting-outputs
dart format lib test
flutter analyze
flutter test
```
