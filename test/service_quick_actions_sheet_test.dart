import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:payqure_home/features/ledger/presentation/widgets/service_quick_actions_sheet.dart';

void main() {
  testWidgets(
    'service quick actions stay compact and expose only key actions',
    (tester) async {
      var selectedAction = '';

      await tester.binding.setSurfaceSize(const Size(320, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ServiceQuickActionsSheet(
              onRecordPayment: () => selectedAction = 'payment',
              onBillingSummary: () => selectedAction = 'billing',
              onManageService: () => selectedAction = 'manage',
            ),
          ),
        ),
      );

      expect(find.text('Quick Actions'), findsOneWidget);
      expect(find.text('Record Payment'), findsOneWidget);
      expect(find.text('Billing Summary'), findsOneWidget);
      expect(find.text('Manage Service'), findsOneWidget);
      expect(find.text('Add Credit'), findsNothing);
      expect(find.text('Generate PDF'), findsNothing);
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Billing Summary'));
      expect(selectedAction, 'billing');

      await tester.tap(find.text('Manage Service'));
      expect(selectedAction, 'manage');
    },
  );
}
