import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../common/widgets/app_snack_bar.dart';
import '../../../../common/widgets/selection_card.dart';
import '../../../../core/theme/accent_color.dart';
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
            color: Theme.of(context).colorScheme.onSurface,
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
        for (var index = 0; index < controller.currencies.length; index++) ...[
          _CurrencyCard(
            currency: controller.currencies[index],
            isSelected:
                controller.currencies[index].code ==
                controller.selectedCurrency.code,
            onTap: () async {
              HapticFeedback.selectionClick();
              await controller.selectCurrency(controller.currencies[index]);
              if (!context.mounted) {
                return;
              }
              AppSnackBar.show(
                context,
                message: '${controller.currencies[index].name} selected.',
              );
            },
          ),
          if (index != controller.currencies.length - 1)
            const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }
}

class _CurrencyCard extends StatelessWidget {
  const _CurrencyCard({
    required this.currency,
    required this.isSelected,
    required this.onTap,
  });

  final AppCurrency currency;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SelectionCard<AppCurrency>(
      value: currency,
      title: currency.code,
      subtitle: Text(
        currency.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w700,
        ),
      ),
      leading: Container(
        width: 48,
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected
              ? context.accent.soft
              : Theme.of(context).colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          _currencyFlag(currency.code),
          style: const TextStyle(fontSize: 24),
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            currency.symbol,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w900,
            ),
          ),
          if (isSelected) ...[
            const SizedBox(width: AppSpacing.sm),
            Icon(
              Icons.check_circle,
              color: Theme.of(context).colorScheme.primary,
            ),
          ],
        ],
      ),
      isSelected: isSelected,
      onTap: (_) => onTap(),
    );
  }

  String _currencyFlag(String code) {
    return switch (code) {
      'INR' => '🇮🇳',
      'USD' => '🇺🇸',
      'EUR' => '🇪🇺',
      'GBP' => '🇬🇧',
      'AED' => '🇦🇪',
      'AUD' => '🇦🇺',
      'CAD' => '🇨🇦',
      'SGD' => '🇸🇬',
      _ => '💱',
    };
  }
}
