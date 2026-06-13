# Ledger Implementation Status Plan

## Summary

The Flutter ledger prototype is now implemented as a functional local-first app with **Supabase Auth + Supabase Postgres sync + Drift/SQLite local cache**. Drift is the offline read/write store. Supabase is the production backend for auth, remote persistence, profile storage, and cross-device sync.

## Completed Coding Work

- Replaced numeric screen indexes with typed route/state management.
- Added Supabase initialization through `--dart-define=SUPABASE_URL=...` and `--dart-define=SUPABASE_PUBLISHABLE_KEY=...`.
- Added register, email verification pending, resend verification email, forgot password, reset OTP, email-or-phone login, and sign out flows.
- Removed phone verification; phone is stored as profile/contact data only.
- Added profile edit screen for name and phone.
- Added Drift/SQLite schema, generated Drift code, local-first repository, local writes, pending sync flags, and remote pull/push sync.
- Added Supabase SQL bootstrap with `profiles`, `services`,
  `service_month_logs`, advances, payments, settlements, schema metadata,
  helper RPCs, and RLS policies.
- Added real domain models for services, entries, advances, bills, profiles, and typed bill calculations.
- Added functional service creation, entry save, advance save, dashboard updates, calendar updates, bill view, and PDF preview generation.
- Redesigned Bills list into clean summary cards with non-wrapping `View Details` and `Record Payment` actions.
- Added a dedicated Bill Detail route/screen for gross amount, advance used, payable, paid, remaining, carry forward, payment history, payment recording, and PDF generation actions.
- Replaced the bulky stock bottom navigation with a compact custom bottom nav and center add action button.
- Updated the center add action to open a grouped bottom sheet for Quick Log Today, Log Past Date, Add Service, Add Advance, and Record Payment.
- Split `RecordPaymentBottomSheet` and `AddAdvanceBottomSheet` out of `ledger_flow_screen.dart` into focused widget files.
- Removed bottom-sheet imports from `ledger_flow_screen.dart` consumers by importing focused widget files directly.
- Split Bills and Bill Detail UI out of `ledger_flow_screen.dart` into `bills_screen.dart`.
- Moved the reusable month dropdown into `month_selector.dart`.
- Updated the Bills, Bill Detail, Record Payment bottom sheet, Payment History, center add sheet, and bottom navigation UI to match the latest provided mock more closely.
- Simplified root navigation to Home, center add action, and More only.
- Rebuilt Home as the primary service hub with settlement-aware monthly summary and tappable service cards.
- Added home summary models and controller-level home summary assembly so Home cards are driven by precomputed settlement data.
- Reworked the global center add sheet into a grouped action list with service selection for service-specific actions.
- Updated More to focus on account, records, preferences, support, and logout instead of duplicated service tabs.
- Added backend schema version checks before remote sync.
- Added tests for auth validation, widget smoke flows, sync conflict behavior, and missing backend migration behavior.

## Verification Commands

- `dart run build_runner build --delete-conflicting-outputs`
- `dart format lib test`
- `flutter analyze`
- `flutter test`

## External Setup Remaining

- Apply
  `supabase/migrations/202606130001_create_payqure_home_production_schema.sql`
  in a new Supabase project.
- Enable Supabase email/password auth and email confirmation.
- Configure Supabase email confirmation and password recovery templates.
- Configure app redirect/deep-link URLs in Supabase and platform settings.
- Run the app with real Supabase values:
  - `--dart-define=SUPABASE_URL=...`
  - `--dart-define=SUPABASE_PUBLISHABLE_KEY=...`

## Ignored By Request

- Phone verification.
- Phone-login email resolution tests.
- PDF share/download work.
- `printing` package Swift Package Manager warning for iOS/macOS.

## Current Pending Coding Work

- Continue splitting the remaining dashboard, quick-log, add-service, more, profile, and PDF preview sections out of `ledger_flow_screen.dart`.
- Implement real Firebase Analytics if product analytics events are still required.
- Replace or monitor the `printing` package iOS/macOS Swift Package Manager warning.
