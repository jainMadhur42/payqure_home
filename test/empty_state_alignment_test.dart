import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:payqure_home/core/theme/app_theme.dart';
import 'package:payqure_home/features/ledger/presentation/screens/contacts_screen.dart';

void main() {
  testWidgets('empty contacts are vertically centered like history screens', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(body: ContactsScreen(services: [])),
      ),
    );

    final title = find.text('No service contacts');
    expect(title, findsOneWidget);
    expect(find.byIcon(Icons.contacts_outlined), findsOneWidget);
    expect(tester.getCenter(title).dy, greaterThan(300));
    expect(tester.getCenter(title).dy, lessThan(540));
    expect(tester.takeException(), isNull);
  });
}
