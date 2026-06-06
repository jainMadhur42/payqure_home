import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../common/widgets/app_card.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../controllers/ledger_controller.dart';

class CurrencyScreen extends StatelessWidget {
  const CurrencyScreen({required this.controller, super.key});

  final LedgerController controller;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Text(
          'Select currency',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w900,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Amounts across the app will use your selected currency symbol.',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (var index = 0; index < controller.currencies.length; index++)
                _CurrencyTile(
                  currency: controller.currencies[index],
                  isSelected:
                      controller.currencies[index].code ==
                      controller.selectedCurrency.code,
                  isLast: index == controller.currencies.length - 1,
                  onTap: () async {
                    HapticFeedback.selectionClick();
                    await controller.selectCurrency(
                      controller.currencies[index],
                    );
                    if (!context.mounted) {
                      return;
                    }
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(
                        SnackBar(
                          content: Text(
                            '${controller.currencies[index].name} selected.',
                          ),
                        ),
                      );
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CurrencyTile extends StatelessWidget {
  const _CurrencyTile({
    required this.currency,
    required this.isSelected,
    required this.isLast,
    required this.onTap,
  });

  final AppCurrency currency;
  final bool isSelected;
  final bool isLast;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          onTap: onTap,
          minLeadingWidth: 44,
          leading: Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primarySoft : AppColors.surface,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              currency.symbol,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: isSelected ? AppColors.primary : AppColors.ink,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          title: Text(
            currency.name,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppColors.ink,
              fontWeight: FontWeight.w800,
            ),
          ),
          subtitle: Text(
            currency.code,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
          ),
          trailing: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: isSelected
                ? const Icon(
                    Icons.check_circle,
                    key: ValueKey('selected'),
                    color: AppColors.primary,
                  )
                : const Icon(
                    Icons.chevron_right,
                    key: ValueKey('unselected'),
                    color: AppColors.muted,
                  ),
          ),
        ),
        if (!isLast)
          const Divider(height: 1, indent: 72, color: AppColors.line),
      ],
    );
  }
}
