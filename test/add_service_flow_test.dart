import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:payqure_home/features/ledger/domain/entities/service_template.dart';
import 'package:payqure_home/features/ledger/domain/entities/service_template_catalog.dart';
import 'package:payqure_home/features/ledger/presentation/models/add_service_draft.dart';
import 'package:payqure_home/features/ledger/presentation/screens/service_template_picker_screen.dart';

void main() {
  test('selected service template pre-populates the add-service draft', () {
    final template = ServiceTemplateCatalog.byId('milkman');

    final draft = AddServiceDraft.fromTemplate(
      template,
      startDate: DateTime(2026, 6, 12),
    );

    expect(draft.serviceName, 'Milkman');
    expect(draft.serviceTemplateName, 'milkman');
    expect(draft.serviceIcon, 'milk');
    expect(draft.templateType, ServiceTemplateType.quantity);
    expect(draft.unit, 'Liter');
    expect(draft.defaultQuantity, 1);
    expect(draft.providerName, isEmpty);
    expect(draft.amount, 0);
  });

  testWidgets('service picker returns the selected template through callback', (
    tester,
  ) async {
    ServiceTemplateDefinition? selected;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ServiceTemplatePickerScreen(
            selectedTemplateId: '',
            embedded: true,
            onSelected: (template) => selected = template,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Milkman').first);
    await tester.pump();

    expect(selected?.id, 'milkman');
  });
}
