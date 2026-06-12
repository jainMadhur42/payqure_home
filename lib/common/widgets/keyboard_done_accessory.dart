import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';

class KeyboardDoneAccessory extends StatelessWidget {
  const KeyboardDoneAccessory({required this.child, super.key});

  /// Height of the "Done" bar shown above the keyboard.
  static const double accessoryHeight = 44;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final keyboardInset = mediaQuery.viewInsets.bottom;
    final isKeyboardOpen = keyboardInset > 0;
    final colorScheme = Theme.of(context).colorScheme;

    return Stack(
      children: [
        // While the keyboard is open the accessory bar occupies [accessoryHeight]
        // just above it. Add that to the bottom inset the screen sees so fields
        // scroll above the bar (not just above the keyboard) and stay visible.
        MediaQuery(
          data: isKeyboardOpen
              ? mediaQuery.copyWith(
                  viewInsets: mediaQuery.viewInsets.copyWith(
                    bottom: keyboardInset + accessoryHeight,
                  ),
                )
              : mediaQuery,
          child: child,
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: keyboardInset,
          child: IgnorePointer(
            ignoring: !isKeyboardOpen,
            child: AnimatedOpacity(
              key: const ValueKey('keyboard-done-accessory'),
              opacity: isKeyboardOpen ? 1 : 0,
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOut,
              child: Material(
                color: colorScheme.surface,
                elevation: 3,
                shadowColor: colorScheme.shadow.withValues(alpha: 0.16),
                child: Container(
                  height: accessoryHeight,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: colorScheme.outlineVariant),
                    ),
                  ),
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    key: const ValueKey('keyboard-done-button'),
                    onPressed: () =>
                        FocusManager.instance.primaryFocus?.unfocus(),
                    child: const Text('Done'),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
