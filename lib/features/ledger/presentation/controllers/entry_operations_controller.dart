import '../../../../core/utils/id_generator.dart';
import '../../domain/entities/household_service.dart';
import '../../domain/entities/ledger_month.dart';
import '../../domain/entities/service_entry.dart';
import '../../domain/entities/service_template.dart';
import '../../domain/repositories/ledger_repository.dart';
import '../../domain/services/entry_amount_calculator.dart';
import '../../domain/services/entry_value_resolver.dart';
import '../../domain/services/service_start_date_resolver.dart';

class EntryOperationsController {
  const EntryOperationsController(this._repository);

  final LedgerRepository _repository;
  final EntryAmountCalculator _amountCalculator = const EntryAmountCalculator();
  final EntryValueResolver _entryValueResolver = const EntryValueResolver();
  final ServiceStartDateResolver _startDateResolver =
      const ServiceStartDateResolver();

  Future<ServiceEntry> save({
    required HouseholdService service,
    required String monthKey,
    required int day,
    required ServiceEntryStatus status,
    required double quantity,
    required String unit,
    required int rateCents,
    required String note,
    void Function(ServiceEntry entry)? onPrepared,
  }) async {
    validateDate(service: service, monthKey: monthKey, day: day);
    final existing = service.entries
        .where((entry) => entry.day == day && entry.monthKey == monthKey)
        .firstOrNull;
    final amountCents = _amountCalculator
        .calculate(
          service: service,
          status: status,
          quantity: quantity,
          rateCents: rateCents,
        )
        .amountCents;
    final now = DateTime.now();
    final entry =
        existing?.copyWith(
          status: status,
          quantity: quantity,
          unit: unit,
          rateCents: rateCents,
          amountCents: amountCents,
          note: note,
          pendingSync: true,
          updatedAt: now,
        ) ??
        ServiceEntry(
          id: IdGenerator.create('entry'),
          serviceId: service.id,
          day: day,
          monthKey: monthKey,
          status: status,
          quantity: quantity,
          unit: unit,
          rateCents: rateCents,
          amountCents: amountCents,
          updatedAt: now,
          note: note,
          pendingSync: true,
        );
    onPrepared?.call(entry);
    await _repository.saveEntry(entry);
    return entry;
  }

  Future<ServiceEntry> saveDefault({
    required HouseholdService service,
    required String monthKey,
    required int day,
    ServiceEntryStatus? status,
    void Function(ServiceEntry entry)? onPrepared,
  }) {
    final effectiveStatus = status ?? ServiceEntryStatus.delivered;
    return save(
      service: service,
      monthKey: monthKey,
      day: day,
      status: effectiveStatus,
      quantity: defaultQuantity(service, effectiveStatus),
      unit: service.unit,
      rateCents: defaultRate(service, monthKey),
      note: '',
      onPrepared: onPrepared,
    );
  }

  Future<ServiceEntry> clear({
    required HouseholdService service,
    required String monthKey,
    required int day,
    void Function(ServiceEntry entry)? onPrepared,
  }) {
    return save(
      service: service,
      monthKey: monthKey,
      day: day,
      status: ServiceEntryStatus.noEntry,
      quantity: 0,
      unit: service.unit,
      rateCents: 0,
      note: '',
      onPrepared: onPrepared,
    );
  }

  void validateDate({
    required HouseholdService service,
    required String monthKey,
    required int day,
  }) {
    final month = LedgerMonth.parse(monthKey);
    final entryDate = DateTime(month.year, month.month, day);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (entryDate.isAfter(today)) {
      throw StateError(
        'Entries can only be logged on or after the service date.',
      );
    }
    final startDate = _startDateResolver.resolve(service);
    if (startDate == null) {
      return;
    }
    final serviceStartDate = DateTime(
      startDate.year,
      startDate.month,
      startDate.day,
    );
    if (entryDate.isBefore(serviceStartDate)) {
      throw StateError(
        'Service started from ${_formatDate(serviceStartDate)} can not update '
        'delivery before that. Edit service started date to mark the entry.',
      );
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  double defaultQuantity(HouseholdService service, ServiceEntryStatus status) {
    if (status == ServiceEntryStatus.notDelivered ||
        status == ServiceEntryStatus.noEntry) {
      return 0;
    }
    if (status == ServiceEntryStatus.halfDay) {
      return 0.5;
    }
    if (service.templateType == ServiceTemplateType.fixedMonthly) {
      return 1;
    }
    return service.defaultQuantity;
  }

  int defaultRate(HouseholdService service, String monthKey) {
    if (service.templateType == ServiceTemplateType.fixedMonthly ||
        (service.templateType == ServiceTemplateType.attendance &&
            service.monthlyAmountCents > 0)) {
      return _entryValueResolver.fixedDailyRateCents(
        service: service,
        monthKey: monthKey,
      );
    }
    return service.rateCents;
  }
}
