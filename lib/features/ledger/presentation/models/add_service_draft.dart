import '../../domain/entities/household_service.dart';
import '../../domain/entities/service_metadata.dart';
import '../../domain/entities/service_template.dart';
import '../../domain/entities/service_template_catalog.dart';

class AddServiceDraft {
  const AddServiceDraft({
    required this.providerName,
    required this.contactNumber,
    required this.serviceTime,
    required this.remindBeforeMinutes,
    required this.startDate,
    required this.serviceName,
    required this.serviceTemplateName,
    required this.serviceIcon,
    required this.templateType,
    required this.unit,
    required this.defaultQuantity,
    required this.amount,
  });

  factory AddServiceDraft.fromService(HouseholdService service) {
    final metadata = ServiceMetadata.parse(service.description);
    final startDate = metadata.startDate ?? DateTime.now();
    final amountCents = service.templateType == ServiceTemplateType.fixedMonthly
        ? service.monthlyAmountCents
        : service.rateCents;
    final template = ServiceTemplateCatalog.forService(
      name: service.name,
      icon: service.icon,
      type: service.templateType,
      templateId: metadata.templateId,
    );
    return AddServiceDraft(
      providerName: metadata.providerName,
      contactNumber: metadata.contactNumber,
      serviceTime: metadata.serviceTime,
      remindBeforeMinutes: metadata.remindBeforeMinutes,
      startDate: startDate,
      serviceName: service.name,
      serviceTemplateName: template.id,
      serviceIcon: service.icon,
      templateType: service.templateType,
      unit: service.unit.isEmpty ? template.defaultUnit : service.unit,
      defaultQuantity: service.defaultQuantity,
      amount: amountCents / 100,
    );
  }

  final String providerName;
  final String contactNumber;
  final String serviceTime;
  final int remindBeforeMinutes;
  final DateTime startDate;
  final String serviceName;
  final String serviceTemplateName;
  final String serviceIcon;
  final ServiceTemplateType templateType;
  final String unit;
  final double defaultQuantity;
  final double amount;

  String get description {
    return ServiceMetadata(
      providerName: providerName,
      contactNumber: contactNumber,
      serviceTime: serviceTime,
      startDate: startDate,
      remindBeforeMinutes: remindBeforeMinutes,
      templateId: serviceTemplateName,
    ).encode();
  }
}
