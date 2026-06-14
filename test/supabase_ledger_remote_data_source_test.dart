import 'package:flutter_test/flutter_test.dart';
import 'package:payqure_home/features/ledger/data/sync/supabase_ledger_remote_data_source.dart';

void main() {
  group('parseLedgerSchemaVersion', () {
    test('returns null for a missing schema version', () {
      expect(parseLedgerSchemaVersion(null), isNull);
    });

    test('accepts scalar numeric and string versions', () {
      expect(parseLedgerSchemaVersion(5), 5);
      expect(parseLedgerSchemaVersion(5.0), 5);
      expect(parseLedgerSchemaVersion('5'), 5);
    });

    test('accepts PostgREST row and list response shapes', () {
      expect(parseLedgerSchemaVersion({'ledger_schema_version': 5}), 5);
      expect(
        parseLedgerSchemaVersion([
          {'version': 5},
        ]),
        5,
      );
    });
  });
}
