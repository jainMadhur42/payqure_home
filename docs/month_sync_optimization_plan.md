# Month Sync Optimization Plan

## Goal

Show authenticated Home data only after the selected month has been hydrated,
while keeping Drift as the offline source and avoiding repeated Supabase calls.

## Changes

1. Make `getOverview` and overview watchers local-only.
2. Persist a successful remote-hydration marker per user and month in
   `sync_metadata_records`.
3. Refresh the current month once per authenticated launch before leaving
   Splash. Fall back to an existing cache if the network is unavailable.
4. Hydrate a selected month only when it has not previously been cached.
5. Keep cached month reads network-free. Pull-to-refresh explicitly forces a
   remote refresh.
6. Fetch the month-scoped Supabase tables in parallel.
7. Keep service definitions shared across months and fetch the following
   month's payment rows only where settlement allocation requires them.
8. Guard month transitions so an older response cannot replace a newer month.
9. Bound remote hydration with a timeout. Cached data remains available
   offline; an uncached failed hydration must not display a misleading empty
   Home screen.

## Verification

- First authenticated launch hydrates the current month before Home appears.
- Returning to a cached month does not call Supabase again.
- Selecting an uncached month hydrates once and stores it in Drift.
- Pull-to-refresh forces one selected-month refresh.
- Rapid month changes cannot show data for the wrong month.
- Local writes remain optimistic and continue syncing in the background.
