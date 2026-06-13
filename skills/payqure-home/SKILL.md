---
name: payqure-home
description: Work safely in the Payqure Home Flutter ledger app. Use for changes involving household services, daily entries, payments, settlements, Drift/SQLite, Supabase Auth/Postgres sync, legal consent, PDF statements, navigation, themes, or tests.
---

# Payqure Home Engineering Skill

Use this guide before modifying the Payqure Home codebase. Read the relevant
source files as well; this document explains ownership and invariants, not every
implementation detail.

## Product

Payqure Home, displayed in some older copy as Daily Service Ledger or Daily
Wages, tracks recurring household services such as milk, maid, water, car wash,
and newspaper.

Core capabilities:

- Create quantity-based, attendance-based, and fixed-monthly services.
- Log daily service status and custom quantity/rate entries.
- Record advances and payments.
- Calculate current-month usage, previous balance, advance, paid amount, and
  amount due.
- Work offline using Drift/SQLite and synchronize with Supabase.
- Generate one-page service statement PDFs.
- Authenticate with email/password and email verification.
- Store phone as profile data; there is no phone verification flow.
- Require acceptance of the current Privacy Policy.

## Start Here

Important entry points:

| Concern | File |
| --- | --- |
| App bootstrap and Supabase initialization | `lib/main.dart` |
| Dependency construction and theme selection | `lib/app.dart` |
| Main UI compatibility facade | `lib/features/ledger/presentation/controllers/ledger_controller.dart` |
| Auth/session policy and operations | `lib/features/ledger/presentation/controllers/session_controller.dart` |
| Month hydration and overview lifecycle | `lib/features/ledger/presentation/controllers/month_data_controller.dart` |
| Root auth/ledger routing | `lib/features/ledger/presentation/screens/ledger_home_screen.dart` |
| Ledger screen routing and More screen | `lib/features/ledger/presentation/screens/ledger_flow_screen.dart` |
| Home dashboard | `lib/features/ledger/presentation/screens/home_screen.dart` |
| Service calendar/detail | `lib/features/ledger/presentation/screens/service_detail_screen.dart` |
| Auth UI | `lib/features/ledger/presentation/screens/login_screen.dart` |
| Drift schema | `lib/features/ledger/data/database/ledger_database.dart` |
| Local-first repository | `lib/features/ledger/data/repositories/drift_ledger_repository.dart` |
| Supabase auth/profile | `lib/features/ledger/data/repositories/supabase_auth_repository.dart` |
| Supabase ledger API | `lib/features/ledger/data/sync/supabase_ledger_remote_data_source.dart` |
| Sync scheduling and deduplication | `lib/features/ledger/data/sync/ledger_sync_coordinator.dart` |
| Drift/Supabase row synchronization | `lib/features/ledger/data/sync/drift_ledger_sync_service.dart` |
| Entry validation and persistence | `lib/features/ledger/presentation/controllers/entry_operations_controller.dart` |
| Payment and advance operations | `lib/features/ledger/presentation/controllers/payment_operations_controller.dart` |
| Ledger analytics event mapping | `lib/features/ledger/presentation/analytics/ledger_analytics_mapper.dart` |
| Reminder permission and schedule reconciliation | `lib/features/ledger/presentation/controllers/service_reminder_coordinator.dart` |
| PDF generation | `lib/features/ledger/data/services/pdf_statement_service.dart` |
| Legal content and policy version | `lib/features/legal/domain/legal_content.dart` |
| Legal screens | `lib/features/legal/presentation/legal_screens.dart` |
| Onboarding flow | `lib/features/onboarding/presentation/onboarding_screen.dart` |
| Supabase migrations | `supabase/migrations/` |

## Architecture

The project uses a pragmatic Clean Architecture split:

```text
presentation
  screens/widgets -> LedgerController
domain
  entities, repository interfaces, pure calculators, use cases
data
  Drift repository, Supabase data sources, mappers, PDF service
```

Rules:

- Widgets render state and dispatch actions. Do not put financial calculations
  or persistence logic in widgets.
- `LedgerController` is the stable screen-facing facade. Route state and
  selected UI entities remain there while session and month lifecycle work is
  delegated to focused controllers.
- `SessionController` owns auth operations and privacy acceptance policy.
- `MonthDataController` owns hydration, overview subscriptions, cancellation,
  and stale month-load rejection.
- Repository interfaces live in `domain/repositories`.
- Pure calculations live in `domain/services`.
- Drift is the immediate UI data source and offline store.
- Supabase is auth, profile, remote persistence, and cross-device sync.
- `LedgerSyncCoordinator` owns sync scheduling, deduplication, and remote
  schema-validation caching.
- `DriftLedgerSyncService` owns remote row transfer, conflict resolution,
  remote row mapping, month cache markers, and logout transfer/cleanup.
- `DriftLedgerRepository` owns local reads/writes, settlement recalculation,
  and per-service serialization.
- Entry and payment operation controllers create and persist domain entities;
  `LedgerController` owns optimistic UI projection, messages, and routes.
- `LedgerAnalyticsMapper` owns analytics labels, event parameters, user
  properties, amount context, and route-to-screen naming. Keep Firebase calls
  in `AppAnalytics`; do not rebuild analytics payload policy inside widgets or
  controllers.
- `ServiceReminderCoordinator` serializes permission checks and schedule
  replacement. Existing permissions restore reminders after authenticated
  service data loads, and app resume forces reconciliation so app upgrades do
  not leave stale or missing OS schedules.
- Writes are local-first where possible. Update UI immediately, then sync.
- Reuse existing theme tokens and common widgets. Do not introduce a separate
  design language for new screens.

## Runtime and Startup

`main.dart` initializes Supabase when configuration is present, then builds
`PayqureHomeApp`.

Supabase values are read through `AppConfig`. Environment overrides:

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=YOUR_PUBLISHABLE_KEY
```

Build modes select safe defaults automatically:

- Debug/profile builds enable verbose diagnostics and disable Firebase
  Analytics/Crashlytics collection, and use the non-production Supabase
  project.
- Release builds disable verbose diagnostics and enable Firebase
  Analytics/Crashlytics collection, and use the production Supabase project.
- `APP_ENV`, Supabase values, and telemetry flags can still be overridden with
  `--dart-define` for CI and targeted verification.
- Android release tasks require an ignored `android/key.properties` created
  from `android/key.properties.example`; never restore debug signing for store
  artifacts.

Startup sequence:

1. Show `SplashScreen`.
2. Show onboarding when `has_seen_onboarding` is not stored locally.
3. Skip/Get Started stores onboarding completion and opens Login.
4. On later launches, `LedgerController.completeSplash()` restores the
   Supabase session.
5. Route to login if there is no session.
6. Route to email verification if the account is unverified.
7. Route to privacy acceptance if policy version is missing or outdated.
8. Otherwise start the ledger and open Home.

Startup must never wait forever for network data:

- Session restoration is bounded.
- Profile reads/upserts use timeouts.
- Home reads local Drift data first.
- Remote ledger synchronization runs in the background.
- On startup failure, leave Splash and show Login with an error.

Do not reintroduce blocking remote sync before the first post-splash route.

## Navigation

Routes are typed in `domain/entities/app_route.dart`.

Root navigation:

```text
Home     +     More
```

- Home contains the month summary and service list.
- The center Add button opens the Service Template Picker directly, then the
  pre-populated Add Service form. It is not a tab and does not open a global
  action sheet.
- More contains account, records, preferences, legal, and logout.
- Contacts is opened from More, not from bottom navigation.
- Calendar, settlement, payments, advances, and PDF are service-specific flows.
- Entry back behavior depends on `EntrySource` (`quickLog` or `calendar`).

When adding a route:

1. Add it to `LedgerRoute`.
2. Render it in the appropriate root switch.
3. Add app-bar title/back behavior.
4. Add route depth for transition direction.
5. Ensure it is not accidentally shown as a bottom-navigation root.

## Authentication and Privacy

`UserProfile` is the single auth/profile domain model. Do not create a second
user model.

Registration collects:

- Name
- Email
- Phone
- Password
- Privacy Policy acceptance

Phone is normalized and stored but not verified.

The production Supabase bootstrap installs `handle_new_auth_user`, an
`auth.users` insert trigger that copies registration name, phone, and privacy
metadata into `public.profiles`. This is required because email-confirmation
signups may not receive an authenticated session immediately. Explicit profile
edits must write `public.profiles` synchronously and surface failures; only
passive session-refresh repair upserts may suppress transient errors.

Current policy metadata is defined only in:

```text
lib/features/legal/domain/legal_content.dart
```

Current version:

```text
2026-06
```

Profile fields:

- `privacyPolicyAccepted`
- `privacyPolicyAcceptedAt`
- `privacyPolicyVersion`

Supabase columns:

- `privacy_policy_accepted`
- `privacy_policy_accepted_at`
- `privacy_policy_version`

Keep consent in both Supabase `profiles` and auth user metadata. Existing users
with no acceptance or an old version must see `PrivacyPolicyAcceptanceView`
after login and before Home.

Long legal text belongs in `LegalContent`, not inside widgets.

## Local Database and Sync

Drift schema: `ledger_database.dart`.

Main tables:

- `profile_records`
- `service_records`
- `service_month_log_records`
- `advance_payment_records`
- `payment_transaction_records`
- `monthly_settlement_records`
- `sync_metadata_records`

Daily entries are stored locally and remotely as one
`service_month_log_records` / `service_month_logs` JSON document per service
and month. `ServiceEntry` remains the domain/UI model and is decoded through
`MonthLogEntryCodec`; there is no legacy per-day entry table.

The monthly entry document uses this shape:

```json
{
  "schemaVersion": 1,
  "overrides": {
    "12": {
      "id": "entry-id",
      "status": "delivered",
      "quantity": 1.5,
      "unit": "L",
      "rateCents": 6000,
      "amountCents": 9000,
      "note": "",
      "updatedAt": "2026-06-12T08:00:00.000Z"
    }
  }
}
```

The key inside `overrides` is the day of month. Keep the domain and UI working
with `ServiceEntry`; persistence conversion belongs in `MonthLogEntryCodec`.
Do not reintroduce `entry_records`, Supabase `service_entries`, or direct JSON
parsing in widgets/controllers.

Current local Drift schema version is `6`. Version 6 removes the obsolete
`entry_records` table for existing development installs. A fresh database
creates only the current table set.

Generated file:

```text
lib/features/ledger/data/database/ledger_database.g.dart
```

After changing Drift tables:

1. Increment `schemaVersion`.
2. Add a forward migration in `onUpgrade`.
3. Run build runner.
4. Add migration/mapper tests.

Never edit the generated `.g.dart` manually.

Sync invariants:

- Stable IDs are shared by Drift and Supabase.
- Local mutations set `pendingSync`.
- Conflict handling is last-write-wins using `updated_at`.
- Soft-deleted ledger rows use `is_deleted`.
- Logout synchronizes user data first and clears local ledger data only after
  successful sync.
- A sync failure during logout must keep local data intact.
- Remote failures during normal Home startup must not hide local data.

## Supabase

Fresh production schema:

```text
supabase/migrations/202606130001_create_payqure_home_production_schema.sql
```

This single bootstrap creates the complete schema at ledger version 5,
including payment allocations, privacy acceptance, OTP request limits, and
optimized service month logs. It is intended for a new Supabase project and
must not be run as a replacement migration on an existing populated database.
It deliberately does not create the obsolete `service_entries` table.

OTP request limiting allows three signup-verification or password-recovery
requests per email and purpose. Support reset instructions are in:

```text
docs/otp_request_support_process.md
```

Future production changes must be added as new incremental migrations after
this bootstrap. Do not edit an already-applied production migration.

RLS must keep every user scoped to their own rows. Ledger tables use `user_id`
directly or inherit ownership through their service relationship.

The app checks the remote ledger schema version before ledger synchronization.
When changing a required remote contract:

1. Add an incremental SQL migration.
2. Update the schema version record/function as needed.
3. Update `requiredRemoteSchemaVersion`.
4. Add a test for missing/outdated schema behavior.

Never embed a Supabase service-role key. Only the public publishable key may be
used by the client.

## Service Model

Service templates are defined in:

```text
lib/features/ledger/domain/entities/service_template_catalog.dart
```

Normal users choose a service template, not an internal calculation engine.
The template maps to:

- Quantity based
- Attendance based
- Fixed monthly

The service stores its icon identifier. Use the same icon on Add Service, Home,
Service Detail, Contacts, and PDFs.

Service start-date invariants:

- A service is visible in its start month and all later months.
- Dates before the start date are disabled in the calendar.
- No entry or charge can be created before the start date.
- Mid-month services calculate only from the start date.
- Do not hardcode example dates.

## Entry Logging

Normal daily logging should use quick actions, not force the full form.

Quantity:

- Delivered
- Not delivered/missed
- Customize quantity/rate

Attendance:

- Present
- Absent
- Half day when supported

Fixed monthly tracking:

- Delivered
- Not delivered

Requirements:

- Apply optimistic local updates so calendar colors and Home amounts change
  immediately.
- Prevent duplicate taps while async persistence finishes.
- Amount is calculated and read-only.
- Decimal quantities are supported.
- Not delivered/absent amounts are zero.
- Full edit UI is for customization or editing an existing entry.
- Calendar dates use color for status; avoid crowded secondary text.

## Financial Calculations

Never calculate settlement totals in UI code.

Pure services:

- `EntryAmountCalculator`
- `MonthlyUsageCalculator`
- `RateResolver`
- `CutoffDateResolver`
- `TillDateSettlementCalculator`
- `SettlementCalculator`
- `PaymentAllocationCalculator`
- `BillCalculator`

Current-month calculations use today as cutoff. Past months use month end.
Future months show zero unless projection is explicitly added later.

Settlement concepts:

```text
usage till cutoff
+ previous unpaid balance
- available advance
- payments
= amount due
```

Payment allocation order in this app:

1. Settle the oldest outstanding month first.
2. Continue chronologically through newer outstanding months.
3. Settle the current month when its turn is reached.
4. Store any remainder as advance.

Do not mark a bill paid unless a payment or applicable advance actually settles
it. A payment may appear in the history of an older month it settled while
retaining the real payment transaction date.

Rate resolution priority:

1. Entry-specific rate
2. Effective date rate history, when available
3. Service default rate

Fixed-monthly tracking must still update delivered/missed statistics and the
monthly amount according to the established calculator behavior.

## UI and Theme

The app supports light, dark, and system theme modes.

Use:

- `AppTheme`
- `AppColors`
- `AppSpacing`
- `AppRadius`
- Existing reusable cards, selectors, service icons, bottom sheets, and buttons

Requirements:

- Test both brightness modes.
- Use `Theme.of(context).colorScheme` for adaptive surfaces/text.
- Avoid hardcoded white backgrounds in sheets and pickers.
- Keep tap targets at least 44 logical pixels.
- Prevent text wrapping in action buttons.
- Keep Home summary-focused; detailed settlement data belongs in detail screens.
- Preserve compact Home / center Add / More navigation.

## PDF Statements

PDF generation is in `PdfStatementService`.

Invariants:

- Statement should fit on one A4 page.
- Use the app logo and Payqure branding.
- Use the bundled Unicode-capable Roboto font for the rupee symbol.
- Calendar cells show date numbers with status color.
- Keep monthly statistics compact.
- Generate PDF for the current service/month; do not redirect to a Bills tab.

After PDF changes, run `pdf_statement_service_test.dart`.

The `printing` package currently emits an iOS/macOS Swift Package Manager
warning. It is known; do not remove PDF support merely to silence it.

## Legal and Data Deletion

More > Legal contains:

- Privacy Policy
- Terms & Disclaimer
- Delete My Data

The data deletion action currently opens a prefilled email and falls back to
copying the configured support address.

Before release, replace:

```text
support@YOURDOMAIN.com
```

with the real support email in `LegalContent`.

## Tests

Test areas:

- `ledger_calculation_test.dart`: entry and usage calculations
- `settlement_calculator_test.dart`: settlement behavior
- `payment_allocation_calculator_test.dart`: payment ordering
- `sync_conflict_test.dart`: local/remote sync and logout safety
- `ledger_calendar_test.dart`: service start-date calendar behavior
- `pdf_statement_service_test.dart`: one-page PDF
- `service_template_catalog_test.dart`: template mapping
- `legal_flow_test.dart`: signup consent, policy gate, and legal navigation
- `onboarding_test.dart`: page flow and first-launch persistence
- `widget_test.dart`: app startup/theme smoke tests

Verification:

```bash
dart run build_runner build --delete-conflicting-outputs
dart format lib test
flutter analyze
flutter test
```

Run build runner only when Drift-generated code needs regeneration.

Known analyzer warning:

```text
printing does not support Swift Package Manager for iOS/macOS
```

Treat new analyzer errors or test failures as regressions; do not dismiss them
because of the known warning.

## Change Workflow

1. Read the controller, domain service, repository, and screen involved.
2. Preserve local-first behavior and route/back semantics.
3. Put business rules in pure domain code.
4. Add migrations for schema changes; never silently assume new columns exist.
5. Add focused unit/widget tests.
6. Format, analyze, and run the full test suite.
7. Inspect `git diff --check` and avoid committing generated build outputs,
   Pods, `.dart_tool`, local credentials, or Xcode user data.

## Common Mistakes

Avoid:

- Blocking Splash on Supabase ledger synchronization.
- Duplicating user/profile models.
- Putting totals or allocation logic in widgets.
- Using full-month amounts for the current month.
- Treating unpaid balances as paid.
- Making services visible only in their creation month.
- Allowing entries before service start.
- Updating calendar state only after remote sync.
- Adding service-specific tabs back to bottom navigation.
- Hardcoding light surfaces that break dark mode.
- Editing Drift generated code by hand.
- Replacing existing architecture with a new state-management framework for a
  small feature.
