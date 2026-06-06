import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../controllers/ledger_controller.dart';
import 'ledger_screen_shared.dart';

class MonthSelector extends StatelessWidget {
  const MonthSelector({required this.controller, super.key});

  final LedgerController controller;

  @override
  Widget build(BuildContext context) {
    final months = _monthOptions(controller.monthKey);
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: controller.monthKey,
          borderRadius: BorderRadius.circular(AppRadius.md),
          icon: const Icon(Icons.keyboard_arrow_down, size: 18),
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: AppColors.ink,
            fontWeight: FontWeight.w800,
          ),
          items: months
              .map(
                (key) => DropdownMenuItem(
                  value: key,
                  child: Text(monthLabelShort(key)),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value != null) {
              controller.selectMonth(value);
            }
          },
        ),
      ),
    );
  }

  List<String> _monthOptions(String activeKey) {
    final base = monthDate(activeKey);
    return List.generate(13, (index) {
      final date = DateTime(base.year, base.month - 6 + index);
      return '${date.year}-${date.month.toString().padLeft(2, '0')}';
    });
  }
}
