import 'package:flutter/material.dart';

import '../../../../common/widgets/app_card.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/entities/household_service.dart';
import '../../domain/entities/monthly_bill.dart';
import '../../domain/entities/monthly_settlement.dart';
import '../../domain/entities/payment_transaction.dart';
import '../controllers/ledger_controller.dart';
import '../widgets/ledger_screen_shared.dart';

class SettlementDetailScreen extends StatelessWidget {
  const SettlementDetailScreen({
    required this.controller,
    required this.service,
    super.key,
  });

  final LedgerController controller;
  final HouseholdService service;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<MonthlyBill>(
      future: controller.loadBillForService(service),
      builder: (context, snapshot) {
        final bill = snapshot.data;
        final settlement = bill?.settlement;
        if (settlement == null) {
          return const Center(child: CircularProgressIndicator());
        }
        return ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            AppCard(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service.name,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    controller.overview?.monthLabel ?? service.monthKey,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: _SettlementHeroAmount(
                          label: 'Remaining',
                          amountCents: settlement.remainingAmountCents,
                        ),
                      ),
                      StatusPill(label: settlement.status.label),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            AppCard(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionHeading('Settlement Summary'),
                  SettlementRow(
                    label: 'Gross Amount',
                    amountCents: settlement.grossAmountCents,
                  ),
                  SettlementRow(
                    label: 'Advance Used',
                    amountCents: settlement.advanceUsedCents,
                  ),
                  SettlementRow(
                    label: 'Payable',
                    amountCents: settlement.payableAmountCents,
                    strong: true,
                  ),
                  SettlementRow(
                    label: 'Paid',
                    amountCents: settlement.paidAmountCents,
                  ),
                  SettlementRow(
                    label: 'Remaining',
                    amountCents: settlement.remainingAmountCents,
                    strong: settlement.remainingAmountCents > 0,
                  ),
                  if (settlement.carryForwardToNextMonthCents > 0)
                    SettlementRow(
                      label: 'Carry Forward',
                      amountCents: settlement.carryForwardToNextMonthCents,
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            AppCard(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionHeading('Payment Breakdown'),
                  if (bill!.payments.isEmpty)
                    const Text('No payments recorded this month.')
                  else
                    ...bill.payments.map(
                      (payment) => SettlementRow(
                        label:
                            '${payment.mode.label} · ${fullDateLabel(payment.paymentDate.day, payment.monthKey)}',
                        amountCents: payment.amountCents,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            AppCard(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionHeading('Advance Breakdown'),
                  if (bill.advances.isEmpty)
                    const Text('No advance used this month.')
                  else
                    ...bill.advances.map(
                      (advance) => SettlementRow(
                        label: fullDateLabel(
                          advance.paidOn.day,
                          monthKeyForDate(advance.paidOn),
                        ),
                        amountCents: advance.amountCents,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            AppCard(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionHeading('Carry Forward Breakdown'),
                  SettlementRow(
                    label: 'Previous Due',
                    amountCents: settlement.previousCarryForwardCents,
                  ),
                  SettlementRow(
                    label: 'Previous Advance',
                    amountCents: settlement.previousAdvanceCents,
                  ),
                  SettlementRow(
                    label: 'Next Month Due',
                    amountCents: settlement.carryForwardToNextMonthCents,
                  ),
                  SettlementRow(
                    label: 'Next Month Advance',
                    amountCents: settlement.advanceToNextMonthCents,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SettlementHeroAmount extends StatelessWidget {
  const _SettlementHeroAmount({required this.label, required this.amountCents});

  final String label;
  final int amountCents;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          CurrencyFormatter.rupees(amountCents / 100),
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}
