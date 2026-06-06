class CutoffDateResolver {
  const CutoffDateResolver();

  DateTime resolve({
    required int selectedMonth,
    required int selectedYear,
    required DateTime today,
  }) {
    final selectedStart = DateTime(selectedYear, selectedMonth);
    final currentStart = DateTime(today.year, today.month);

    if (selectedStart.year == currentStart.year &&
        selectedStart.month == currentStart.month) {
      return DateTime(selectedYear, selectedMonth, today.day);
    }
    if (selectedStart.isBefore(currentStart)) {
      return DateTime(selectedYear, selectedMonth + 1, 0);
    }
    return selectedStart.subtract(const Duration(days: 1));
  }
}
