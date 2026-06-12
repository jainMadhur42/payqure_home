import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:payqure_home/common/widgets/keyboard_done_accessory.dart';

void main() {
  testWidgets('Done accessory dismisses the focused field', (tester) async {
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(390, 844),
            viewInsets: EdgeInsets.only(bottom: 300),
          ),
          child: KeyboardDoneAccessory(
            child: Scaffold(
              body: TextField(
                focusNode: focusNode,
                decoration: const InputDecoration(labelText: 'Note'),
              ),
            ),
          ),
        ),
      ),
    );

    focusNode.requestFocus();
    await tester.pump();
    expect(focusNode.hasFocus, isTrue);
    expect(find.byKey(const ValueKey('keyboard-done-button')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('keyboard-done-button')));
    await tester.pumpAndSettle();

    expect(focusNode.hasFocus, isFalse);
  });

  testWidgets(
    'reserves space above the keyboard so fields scroll clear of the bar',
    (tester) async {
      late double childInset;

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(390, 844),
              viewInsets: EdgeInsets.only(bottom: 300),
            ),
            child: KeyboardDoneAccessory(
              child: Builder(
                builder: (context) {
                  childInset = MediaQuery.viewInsetsOf(context).bottom;
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
        ),
      );

      expect(childInset, 300 + KeyboardDoneAccessory.accessoryHeight);
    },
  );

  testWidgets('does not inflate the inset when the keyboard is closed', (
    tester,
  ) async {
    late double childInset;

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(size: Size(390, 844)),
          child: KeyboardDoneAccessory(
            child: Builder(
              builder: (context) {
                childInset = MediaQuery.viewInsetsOf(context).bottom;
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      ),
    );

    expect(childInset, 0);
  });

  testWidgets('Done accessory works for fields inside bottom sheets', (
    tester,
  ) async {
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(viewInsets: const EdgeInsets.only(bottom: 300)),
          child: KeyboardDoneAccessory(child: child ?? const SizedBox.shrink()),
        ),
        home: Builder(
          builder: (context) => Scaffold(
            body: FilledButton(
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                builder: (_) => TextField(
                  focusNode: focusNode,
                  decoration: const InputDecoration(labelText: 'Payment note'),
                ),
              ),
              child: const Text('Open payment'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open payment'));
    await tester.pumpAndSettle();
    focusNode.requestFocus();
    await tester.pump();

    expect(focusNode.hasFocus, isTrue);
    expect(find.byKey(const ValueKey('keyboard-done-button')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('keyboard-done-button')));
    await tester.pumpAndSettle();

    expect(focusNode.hasFocus, isFalse);
  });
}
