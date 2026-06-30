import 'package:flutter_test/flutter_test.dart';
import 'package:payqure_home/features/ledger/domain/entities/service_template.dart';
import 'package:payqure_home/features/ledger/domain/entities/service_template_catalog.dart';

void main() {
  test('household templates map to their calculation types', () {
    expect(
      ServiceTemplateCatalog.byId('milkman').templateType,
      ServiceTemplateType.quantity,
    );
    expect(
      ServiceTemplateCatalog.byId('maid').templateType,
      ServiceTemplateType.attendance,
    );
    expect(
      ServiceTemplateCatalog.byId('newspaper').templateType,
      ServiceTemplateType.fixedMonthly,
    );
  });

  test('template units use household-friendly defaults', () {
    expect(ServiceTemplateCatalog.byId('milkman').defaultUnit, 'Liter');
    expect(ServiceTemplateCatalog.byId('water_can').defaultUnit, 'Can');
    expect(
      ServiceTemplateCatalog.byId('flower_maala_delivery').defaultUnit,
      'Packet',
    );
    expect(ServiceTemplateCatalog.byId('maid').defaultUnit, 'Day');
    expect(ServiceTemplateCatalog.byId('newspaper').defaultUnit, 'Month');
  });

  test('advanced custom templates remain available at the bottom', () {
    final customTemplates = ServiceTemplateCatalog.templates
        .where((template) => template.isCustom)
        .toList();

    expect(customTemplates, hasLength(3));
    expect(
      customTemplates.map((template) => template.templateType),
      containsAll(ServiceTemplateType.values),
    );
  });

  test('every built-in category maps to the correct entry action policy', () {
    final builtInTemplates = ServiceTemplateCatalog.templates.where(
      (template) => !template.isCustom,
    );

    for (final template in builtInTemplates) {
      final expectedType = switch (template.category) {
        ServiceTemplateCategory.daily => ServiceTemplateType.quantity,
        ServiceTemplateCategory.attendance => ServiceTemplateType.attendance,
        ServiceTemplateCategory.monthly => ServiceTemplateType.fixedMonthly,
        ServiceTemplateCategory.custom => throw StateError(
          '${template.id} is marked built-in but uses the custom category',
        ),
      };
      expect(
        template.templateType,
        expectedType,
        reason: '${template.title} is mapped to the wrong service category',
      );
    }
  });
}
