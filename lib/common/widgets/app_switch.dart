import 'package:flutter/material.dart';

class AppSwitch extends StatelessWidget {
  const AppSwitch({required this.value, required this.onChanged, super.key});

  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Switch.adaptive(
      value: value,
      onChanged: onChanged,
      activeThumbColor: colorScheme.onPrimary,
      activeTrackColor: colorScheme.primary,
      applyCupertinoTheme: true,
    );
  }
}
