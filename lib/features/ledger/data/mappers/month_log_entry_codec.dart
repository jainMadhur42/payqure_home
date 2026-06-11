import 'dart:convert';

import '../../domain/entities/service_entry.dart';

class MonthLogEntryCodec {
  const MonthLogEntryCodec._();

  static const schemaVersion = 1;

  static String emptyJson() {
    return jsonEncode({
      'schemaVersion': schemaVersion,
      'overrides': <String, Object?>{},
    });
  }

  static String encode(List<ServiceEntry> entries) {
    final sorted = [...entries]..sort((a, b) => a.day.compareTo(b.day));
    return jsonEncode({
      'schemaVersion': schemaVersion,
      'overrides': {
        for (final entry in sorted) entry.day.toString(): _entryToJson(entry),
      },
    });
  }

  static String upsert({
    required String entriesJson,
    required ServiceEntry entry,
  }) {
    final map = _decodeRoot(entriesJson);
    final overrides = _overrides(map);
    overrides[entry.day.toString()] = _entryToJson(entry);
    map['schemaVersion'] = schemaVersion;
    map['overrides'] = overrides;
    return jsonEncode(map);
  }

  static List<ServiceEntry> decode({
    required String entriesJson,
    required String serviceId,
    required String monthKey,
    bool pendingSync = false,
  }) {
    final overrides = _overrides(_decodeRoot(entriesJson));
    final entries = <ServiceEntry>[];
    for (final item in overrides.entries) {
      final day = int.tryParse(item.key);
      final value = item.value;
      if (day == null || value is! Map) {
        continue;
      }
      entries.add(
        ServiceEntry(
          id: _string(value['id'], 'entry-$serviceId-$monthKey-$day'),
          serviceId: serviceId,
          day: day,
          monthKey: monthKey,
          status: _status(_string(value['status'], 'noEntry')),
          quantity: _double(value['quantity']),
          unit: _string(value['unit'], ''),
          rateCents: _int(value['rateCents']),
          amountCents: _int(value['amountCents']),
          note: _string(value['note'], ''),
          updatedAt: _date(value['updatedAt']),
          pendingSync: pendingSync,
        ),
      );
    }
    entries.sort((a, b) => a.day.compareTo(b.day));
    return entries;
  }

  static Map<String, Object?> _entryToJson(ServiceEntry entry) {
    return {
      'id': entry.id,
      'status': entry.status.name,
      'quantity': entry.quantity,
      'unit': entry.unit,
      'rateCents': entry.rateCents,
      'amountCents': entry.amountCents,
      'note': entry.note,
      'updatedAt': entry.updatedAt.toIso8601String(),
    };
  }

  static Map<String, Object?> _decodeRoot(String json) {
    if (json.trim().isEmpty) {
      return {'schemaVersion': schemaVersion, 'overrides': <String, Object?>{}};
    }
    try {
      final decoded = jsonDecode(json);
      if (decoded is Map) {
        return decoded.cast<String, Object?>();
      }
    } catch (_) {
      // A malformed month log should not crash calendar rendering. Treat it
      // as empty and let the next write repair the JSON shape.
    }
    return {'schemaVersion': schemaVersion, 'overrides': <String, Object?>{}};
  }

  static Map<String, Object?> _overrides(Map<String, Object?> root) {
    final value = root['overrides'];
    if (value is Map) {
      return value.cast<String, Object?>();
    }
    return <String, Object?>{};
  }

  static ServiceEntryStatus _status(String value) {
    return ServiceEntryStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => ServiceEntryStatus.noEntry,
    );
  }

  static DateTime _date(Object? value) {
    if (value is DateTime) {
      return value;
    }
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value) ?? DateTime.fromMillisecondsSinceEpoch(0);
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  static double _double(Object? value) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value) ?? 0;
    }
    return 0;
  }

  static int _int(Object? value) {
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }

  static String _string(Object? value, String fallback) {
    if (value == null) {
      return fallback;
    }
    return value.toString();
  }
}
