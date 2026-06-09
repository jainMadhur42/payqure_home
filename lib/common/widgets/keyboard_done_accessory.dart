import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';

class KeyboardDoneAccessory extends StatelessWidget {
  const KeyboardDoneAccessory({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final isKeyboardOpen = keyboardInset > 0;
    final colorScheme = Theme.of(context).colorScheme;

    return Stack(
      children: [
        child,
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
                  height: 44,
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
