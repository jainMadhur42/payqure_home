# Payqure Home Architecture Audit

## Current Architecture

```text
main.dart
  -> initializes Supabase
  -> PayqureHomeApp builds dependencies
     -> LedgerDatabase (Drift/SQLite)
     -> SupabaseAuthRepository
     -> SupabaseLedgerRemoteDataSource
     -> DriftLedgerRepository
     -> LedgerController

Presentation
  screens/widgets
    -> dispatch commands to LedgerController
    -> render LedgerOverview and selected entities

Domain
  entities
  repository interfaces
  pure calculators and use cases

Data
  Drift schema and mappers
  local-first repository
  Supabase auth and ledger data sources
  PDF generation
```

### Runtime Data Flow

1. Splash restores the Supabase session.
2. The current month is hydrated from Supabase into Drift.
3. UI reads `LedgerOverview` from Drift.
4. Local mutations update Drift first and mark rows as pending sync.
5. The controller applies optimistic UI state.
6. Background synchronization pushes pending rows to Supabase.
7. Remote hydration uses last-write-wins conflict resolution.

## Critical Problem Areas

### P0: Oversized Orchestration Classes

- `LedgerController` owns authentication, navigation, service CRUD, entries,
  payments, PDF orchestration, preferences, month loading, and UI messages.
- `DriftLedgerRepository` owns CRUD, calculation persistence, payment
  allocation, sync scheduling, conflict resolution, cache state, and logout.
- `ledger_flow_screen.dart` owns routing plus several unrelated screen
  implementations.

These classes have too many reasons to change and create broad regression risk.

### P0: Repeated Financial Query Chains

Home previously loaded a complete `MonthlyBill` and then loaded the same
advances, payments, previous settlement, and usage again for the till-date
summary. `getOverview` also recalculated every service bill even though those
totals are not used by Home.

### P0: Incomplete Reactive Database Coverage

The overview stream watched only `service_records`. Entry, payment, advance, or
settlement changes required controller-managed refreshes and could leave stale
state if a new write path forgot that refresh.

### P1: Whole-App Rebuilds

`MaterialApp` listened to every `LedgerController` notification. A daily entry
or loading-state update rebuilt the complete application shell even though only
theme changes require rebuilding `MaterialApp`.

### P1: Metadata Stored as Presentation Text

Provider, contact, reminder, template, time, and start date are encoded inside
the service description using a bullet-separated string. Multiple layers parsed
that string independently. This is fragile, not queryable, and difficult to
migrate or localize.

### P1: Sync Is Row-Serial

Pending rows are pushed one at a time and acknowledged individually. This is
correct but scales poorly for large histories and logout synchronization.

### P1: Generated Settlements Mix Read And Write Behavior

Several read paths recalculate and persist settlements. Reads therefore have
side effects and may trigger reactive stream updates, pending synchronization,
and additional reads.

### P2: UI And PDF Monoliths

The PDF service and several screens are over 1,000 lines. Layout, formatting,
data interpretation, and actions are coupled, making visual changes risky.

### P2: Error Observability

Several background operations intentionally swallow errors. The user flow
continues, but production diagnostics cannot distinguish transient failures,
schema mismatch, or data corruption without structured logging.

## Refactors Implemented

### Home Query Reduction

- Removed unused `MonthlyBill` from `HomeServiceSummary`.
- Home now computes only the till-date summary it renders.
- Overview totals use one bulk settlement query plus one following-month
  payment query instead of a bill calculation per service.

### Correct Reactive Overview

- Drift overview watches services, entries, advances, payments, and settlements.
- Entry changes now update overview subscribers without manual refresh coupling.
- Child-table watches are scoped through the owning user's services.

### Central Service Metadata

- Added `ServiceMetadata` as the single parser and serializer.
- Start-date resolution, repository month correction, controller edit drafts,
  and UI provider/contact helpers now share the same implementation.
- Existing description storage remains compatible, so behavior and schema are
  unchanged.

### Rebuild Isolation

- Theme state now uses a dedicated `ValueNotifier<ThemeMode>`.
- `MaterialApp` rebuilds only for theme changes, not every ledger notification.

### Month And Home Domain Extraction

- Added `LedgerMonth` as the single month-key parser and arithmetic value
  object across presentation, domain, repository, and Supabase code.
- Moved Home metric and summary construction into the pure
  `HomeSummaryBuilder` domain service.
- Batched overview entry loading into one Drift query instead of one query per
  service.
- Coalesced the initial multi-table Drift watch burst so one logical database
  change produces one overview reload.

### Session, Month, And Sync Ownership

- Extracted authentication operations and privacy-policy gating into
  `SessionController`; `LedgerController` remains a compatibility facade for
  the current screens.
- Extracted month hydration, overview subscriptions, generation checks, stale
  result rejection, and cancellation into `MonthDataController`.
- Extracted pending-sync serialization, repeated-sync replay, schema validation
  caching, background scheduling, and month-hydration deduplication into
  `LedgerSyncCoordinator`.
- `DriftLedgerRepository` now owns local persistence and settlement mechanics
  rather than synchronization lifecycle or remote row-transfer state.

### Sync Data Plane And Ledger Operations

- Moved remote row push/pull, conflict decisions, month cache markers, logout
  transfer, and local cleanup into `DriftLedgerSyncService`.
- Reduced `DriftLedgerRepository` to local reads/writes, settlement
  recalculation, and per-service serialization.
- Moved entry construction, validation, default values, amount calculation,
  and persistence into `EntryOperationsController`.
- Moved payment/advance construction, mutation, and history aggregation into
  `PaymentOperationsController`.
- `LedgerController` keeps only presentation-facing orchestration such as
  optimistic state patching, loading/error state, messages, and navigation.

## Recommended Refactor Strategy

### Phase 1: Split Application State

Create focused controllers:

```text
SessionController
MonthController
LedgerOverviewController
ServiceDetailController
EntryController
PaymentController
PreferenceController
```

Keep typed navigation in a small coordinator. Widgets should subscribe only to
the state they render.

### Phase 2: Split Repository Responsibilities

```text
LocalLedgerDataSource
RemoteLedgerDataSource
LedgerReadRepository
LedgerWriteRepository
SettlementStore
SyncCoordinator
ConflictResolver
```

Remote DTO mapping and local persistence should not live inside synchronization
loops.

### Phase 3: Add Structured Service Columns

Migrate provider, contact, start date, service time, reminder, template ID, and
inactive date into explicit Drift and Supabase columns. Keep
`ServiceMetadata.parse` only as a backwards-compatible migration adapter.

### Phase 4: Materialize Monthly Read Models

Store or query one monthly service summary projection containing usage,
previous balance, advance, paid amount, and net due. Home should load all cards
with one query instead of service-by-service calculations.

### Phase 5: Batch Synchronization

- Push rows in bounded batches.
- Store per-table sync cursors.
- Fetch only rows updated after the cursor.
- Add retry classification and exponential backoff.
- Record structured sync diagnostics.

### Phase 6: Split UI And PDF Modules

Move each route into its own screen file and split PDF sections into independent
builders. Keep formatting and statement data preparation outside rendering.

## Production Guardrails

- No financial calculations inside widgets.
- No network calls from local read methods.
- No read method should persist data implicitly.
- Every background failure must be observable.
- Every new table mutation must have a reactive-stream test.
- Every sync mutation must have conflict, retry, and offline tests.
- Keep generated files out of manual review and edits.
