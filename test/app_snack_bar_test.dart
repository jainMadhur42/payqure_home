import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:payqure_home/common/widgets/app_snack_bar.dart';
import 'package:payqure_home/core/theme/app_theme.dart';

void main() {
  for (final theme in <({String name, ThemeData data})>[
    (name: 'light', data: AppTheme.light()),
    (name: 'dark', data: AppTheme.dark()),
  ]) {
    testWidgets('app snackbar is readable in ${theme.name} mode', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(320, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          theme: theme.data,
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: FilledButton(
                  onPressed: () => AppSnackBar.show(
                    context,
                    message: 'Payment recorded successfully.',
                  ),
                  child: const Text('Show'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pump();

      expect(find.text('Payment recorded successfully.'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
      expect(find.byTooltip('Dismiss'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('error snackbar uses the error presentation', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => AppSnackBar.show(
                context,
                message: 'Could not save the entry.',
                tone: AppSnackBarTone.error,
              ),
              child: const Text('Show error'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Show error'));
    await tester.pump();

    expect(find.byIcon(Icons.error_rounded), findsOneWidget);
    expect(find.text('Could not save the entry.'), findsOneWidget);
  });
}
