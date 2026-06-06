import '../../../../core/utils/currency_formatter.dart';
import 'service_entry.dart';
import 'service_template.dart';

class HouseholdService {
  const HouseholdService({
    required this.id,
    required this.userId,
    required this.name,
    required this.description,
    required this.icon,
    required this.templateType,
    required this.monthKey,
    required this.unit,
    required this.defaultQuantity,
    required this.rateCents,
    required this.monthlyAmountCents,
    required this.entries,
    required this.updatedAt,
    this.pendingSync = false,
  });

  final String id;
  final String userId;
  final String name;
  final String description;
  final String icon;
  final ServiceTemplateType templateType;
  final String monthKey;
  final String unit;
  final double defaultQuantity;
  final int rateCents;
  final int monthlyAmountCents;
  final List<ServiceEntry> entries;
  final bool pendingSync;
  final DateTime updatedAt;

  String get rateLabel {
    final amount = rateCents / 100;
    final formatted = amount.toStringAsFixed(
      amount.truncateToDouble() == amount ? 0 : 2,
    );
    return unit.isEmpty
        ? '${CurrencyFormatter.symbol}$formatted / Month'
        : '${CurrencyFormatter.symbol}$formatted / $unit';
  }

  int get monthlyAmount => (monthlyAmountCents / 100).round();

  HouseholdService copyWith({
    String? name,
    String? description,
    String? icon,
    ServiceTemplateType? templateType,
    String? monthKey,
    String? unit,
    double? defaultQuantity,
    int? rateCents,
    int? monthlyAmountCents,
    List<ServiceEntry>? entries,
    bool? pendingSync,
    DateTime? updatedAt,
  }) {
    return HouseholdService(
      id: id,
      userId: userId,
      name: name ?? this.name,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      templateType: templateType ?? this.templateType,
      monthKey: monthKey ?? this.monthKey,
      unit: unit ?? this.unit,
      defaultQuantity: defaultQuantity ?? this.defaultQuantity,
      rateCents: rateCents ?? this.rateCents,
      monthlyAmountCents: monthlyAmountCents ?? this.monthlyAmountCents,
      entries: entries ?? this.entries,
      pendingSync: pendingSync ?? this.pendingSync,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
