import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:payqure_home/core/theme/app_theme.dart';
import 'package:payqure_home/features/ledger/data/database/ledger_database.dart';
import 'package:payqure_home/features/ledger/data/repositories/drift_ledger_repository.dart';
import 'package:payqure_home/features/ledger/data/repositories/supabase_auth_repository.dart';
import 'package:payqure_home/features/ledger/data/services/pdf_statement_service.dart';
import 'package:payqure_home/features/ledger/data/sync/supabase_ledger_remote_data_source.dart';
import 'package:payqure_home/features/ledger/domain/entities/service_template.dart';
import 'package:payqure_home/features/ledger/domain/entities/service_template_catalog.dart';
import 'package:payqure_home/features/ledger/domain/entities/app_route.dart';
import 'package:payqure_home/features/ledger/presentation/controllers/ledger_controller.dart';
import 'package:payqure_home/features/ledger/presentation/models/add_service_draft.dart';
import 'package:payqure_home/features/ledger/presentation/screens/ledger_flow_screen.dart';
import 'package:payqure_home/features/ledger/presentation/widgets/service_identity_header.dart';
import 'package:payqure_home/features/ledger/presentation/screens/service_template_picker_screen.dart';
import 'package:payqure_home/features/ledger/presentation/screens/unit_picker_screen.dart';

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

    await tester.scrollUntilVisible(
      find.text('Custom Services'),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      find.text('Create your own service using the option that fits it best.'),
      findsOneWidget,
    );
    expect(find.text('Create your own service'), findsNothing);
  });

  testWidgets('service and unit pickers use readable dark theme text', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: const ServiceTemplatePickerScreen(selectedTemplateId: 'milkman'),
      ),
    );

    final serviceContext = tester.element(find.text('Milkman').first);
    final serviceText = tester.widget<Text>(find.text('Milkman').first);
    expect(
      serviceText.style?.color,
      Theme.of(serviceContext).colorScheme.onSurface,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: const UnitPickerScreen(
          units: ['Liter', 'Packet'],
          selectedUnit: 'Liter',
          serviceName: 'Milkman',
        ),
      ),
    );

    final unitContext = tester.element(find.text('Liter'));
    final unitText = tester.widget<Text>(find.text('Liter'));
    expect(unitText.style?.color, Theme.of(unitContext).colorScheme.onSurface);
  });

  testWidgets('add service validates only the field being edited', (
    tester,
  ) async {
    final database = LedgerDatabase(NativeDatabase.memory());
    final authRepository = SupabaseAuthRepository(client: null);
    final controller = LedgerController(
      authRepository: authRepository,
      ledgerRepository: DriftLedgerRepository(
        database: database,
        remoteDataSource: SupabaseLedgerRemoteDataSource(null),
      ),
      pdfStatementService: const PdfStatementService(),
    );

    try {
      await controller.bypassLoginForDevelopment();
      controller.selectServiceTemplate(ServiceTemplateCatalog.byId('milkman'));

      await tester.pumpWidget(
        MaterialApp(home: LedgerFlowScreen(controller: controller)),
      );
      await tester.pump();

      await tester.enterText(
        find.byKey(const ValueKey('service-provider-name')),
        'Kuldeep',
      );
      await tester.pump();

      expect(find.text('Required'), findsNothing);
    } finally {
      controller.dispose();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 50));
      await authRepository.dispose();
      await database.close();
    }
  });

  testWidgets('service review remains scrollable on a small phone', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(375, 640));
    final database = LedgerDatabase(NativeDatabase.memory());
    final authRepository = SupabaseAuthRepository(client: null);
    final controller = LedgerController(
      authRepository: authRepository,
      ledgerRepository: DriftLedgerRepository(
        database: database,
        remoteDataSource: SupabaseLedgerRemoteDataSource(null),
      ),
      pdfStatementService: const PdfStatementService(),
    );

    try {
      await controller.bypassLoginForDevelopment();
      controller.reviewAddService(
        AddServiceDraft(
          providerName: 'Kuldeep',
          contactNumber: '+91 7240873997',
          serviceTime: '8:30 AM',
          remindBeforeMinutes: 15,
          startDate: DateTime(2026, 6),
          serviceName: 'Milkman',
          serviceTemplateName: 'milkman',
          serviceIcon: 'milk',
          templateType: ServiceTemplateType.quantity,
          unit: 'Liter',
          defaultQuantity: 0.5,
          amount: 61,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(home: LedgerFlowScreen(controller: controller)),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('service-review-scroll-view')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('service-review-hero-card')),
        findsOneWidget,
      );
      expect(find.byType(ServiceIdentityHeader), findsOneWidget);
      expect(find.text('Provider: Kuldeep'), findsOneWidget);
      expect(find.text('Quantity Based'), findsOneWidget);
      expect(find.text('Provider Details'), findsOneWidget);
      expect(find.text('Schedule & Reminder'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('Create Service'),
        300,
        scrollable: find.descendant(
          of: find.byKey(const ValueKey('service-review-scroll-view')),
          matching: find.byType(Scrollable),
        ),
      );
      expect(find.text('Create Service'), findsOneWidget);
    } finally {
      controller.dispose();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 50));
      await authRepository.dispose();
      await database.close();
      await tester.binding.setSurfaceSize(null);
    }
  });

  test('creating a reviewed service opens its service detail screen', () async {
    final database = LedgerDatabase(NativeDatabase.memory());
    final authRepository = SupabaseAuthRepository(client: null);
    final controller = LedgerController(
      authRepository: authRepository,
      ledgerRepository: DriftLedgerRepository(
        database: database,
        remoteDataSource: SupabaseLedgerRemoteDataSource(null),
      ),
      pdfStatementService: const PdfStatementService(),
    );

    try {
      await controller.bypassLoginForDevelopment();
      controller.reviewAddService(
        AddServiceDraft(
          providerName: 'Kuldeep',
          contactNumber: '+91 7240873997',
          serviceTime: '8:30 AM',
          remindBeforeMinutes: 15,
          startDate: DateTime.now(),
          serviceName: 'Milkman',
          serviceTemplateName: 'milkman',
          serviceIcon: 'milk',
          templateType: ServiceTemplateType.quantity,
          unit: 'Liter',
          defaultQuantity: 1,
          amount: 60,
        ),
      );

      await controller.saveDraftService();

      expect(controller.route, LedgerRoute.calendar);
      expect(controller.selectedService?.name, 'Milkman');
      expect(controller.addServiceDraft, isNull);
    } finally {
      controller.dispose();
      await authRepository.dispose();
      await database.close();
    }
  });
}
