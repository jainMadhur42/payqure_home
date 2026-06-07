class LedgerMonth {
  const LedgerMonth._(this.year, this.month);

  factory LedgerMonth(int year, int month) {
    final normalized = DateTime(year, month);
    return LedgerMonth._(normalized.year, normalized.month);
  }

  factory LedgerMonth.fromDate(DateTime date) {
    return LedgerMonth._(date.year, date.month);
  }

  factory LedgerMonth.parse(String value, {DateTime? fallback}) {
    final parts = value.split('-');
    final fallbackDate = fallback ?? DateTime.now();
    final year = parts.isNotEmpty
        ? int.tryParse(parts.first) ?? fallbackDate.year
        : fallbackDate.year;
    final month = parts.length > 1
        ? int.tryParse(parts[1]) ?? fallbackDate.month
        : fallbackDate.month;
    return LedgerMonth(year, month);
  }

  final int year;
  final int month;

  DateTime get firstDay => DateTime(year, month);

  int get daysInMonth => DateTime(year, month + 1, 0).day;

  LedgerMonth shift(int delta) {
    return LedgerMonth(year, month + delta);
  }

  String get key => '$year-${month.toString().padLeft(2, '0')}';

  @override
  String toString() => key;

  @override
  bool operator ==(Object other) {
    return other is LedgerMonth && other.year == year && other.month == month;
  }

  @override
  int get hashCode => Object.hash(year, month);
}
