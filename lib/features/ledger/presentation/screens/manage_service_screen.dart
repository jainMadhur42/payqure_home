import 'package:flutter/material.dart';

import '../../../../common/widgets/app_card.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/app_route.dart';
import '../../domain/entities/household_service.dart';
import '../../domain/entities/service_template.dart';
import '../controllers/ledger_controller.dart';
import '../widgets/add_advance_bottom_sheet.dart';
import '../widgets/ledger_screen_shared.dart';
import '../widgets/manage_service_action_tile.dart';
import '../widgets/record_payment_bottom_sheet.dart';
import '../widgets/service_icon.dart';

class ManageServiceScreen extends StatelessWidget {
  const ManageServiceScreen({
    required this.controller,
    required this.service,
    super.key,
  });

  final LedgerController controller;
  final HouseholdService service;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.xxl,
      ),
      children: [
        _ServiceIdentityCard(service: service),
        const SizedBox(height: AppSpacing.xl),
        _ManageSection(
          title: 'Financial',
          children: [
            ManageServiceActionTile(
              icon: Icons.payments_outlined,
              title: 'Record Payment',
              subtitle: 'Settle or record a payment',
              tintColor: AppColors.success,
              onTap: () => _showRecordPayment(context),
            ),
            ManageServiceActionTile(
              icon: Icons.account_balance_wallet_outlined,
              title: 'Add Credit',
              subtitle: 'Record advance or extra amount',
              tintColor: AppColors.success,
              onTap: () => _showAddCredit(context),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        _ManageSection(
          title: 'History',
          children: [
            ManageServiceActionTile(
              icon: Icons.account_balance_outlined,
              title: 'Billing Summary',
              subtitle: 'Usage, dues and balances',
              tintColor: AppColors.info,
              onTap: () => controller.openSettlementDetail(
                service,
                returnRoute: LedgerRoute.manageService,
              ),
            ),
            ManageServiceActionTile(
              icon: Icons.history_outlined,
              title: 'Transaction History',
              subtitle: 'Recorded service payments',
              tintColor: AppColors.info,
              onTap: () => controller.openPaymentHistory(
                service,
                returnRoute: LedgerRoute.manageService,
              ),
            ),
            ManageServiceActionTile(
              icon: Icons.savings_outlined,
              title: 'Advance History',
              subtitle: 'Advance and credit payments',
              tintColor: AppColors.info,
              onTap: () => controller.openAdvanceHistory(
                service,
                returnRoute: LedgerRoute.manageService,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        _ManageSection(
          title: 'Documents',
          children: [
            ManageServiceActionTile(
              icon: Icons.picture_as_pdf_outlined,
              title: 'Generate PDF',
              subtitle: 'Export monthly statement',
              tintColor: AppColors.primary,
              onTap: () => _generatePdf(context),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        _ManageSection(
          title: 'Service Settings',
          children: [
            ManageServiceActionTile(
              icon: Icons.edit_outlined,
              title: 'Edit Service',
              subtitle: 'Change provider, rate or defaults',
              tintColor: AppColors.primary,
              onTap: () => controller.startEditService(
                service,
                returnRoute: LedgerRoute.manageService,
              ),
            ),
            ManageServiceActionTile(
              icon: Icons.delete_outline,
              title: 'Delete Service',
              subtitle: 'Remove service permanently',
              destructive: true,
              onTap: () => _confirmDelete(context),
            ),
          ],
        ),
      ],
    );
  }

  void _showRecordPayment(BuildContext context) {
    controller.trackRecordPaymentStarted(
      service: service,
      source: 'manage_service',
    );
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RecordPaymentBottomSheet(
        controller: controller,
        service: service,
        source: 'manage_service',
        returnRoute: LedgerRoute.manageService,
      ),
    );
  }

  void _showAddCredit(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddAdvanceBottomSheet(
        controller: controller,
        serviceId: service.id,
        serviceName: service.name,
        month: controller.overview?.monthLabel ?? service.monthKey,
        title: 'Add Credit',
        onSaved: () {},
      ),
    );
  }

  Future<void> _generatePdf(BuildContext context) async {
    try {
      await controller.loadSelectedBill();
      controller.openPdfPreview(source: PdfSource.manageService);
    } catch (error) {
      debugPrint('Could not generate PDF: $error');
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Could not generate PDF. Please try again.'),
          ),
        );
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Service?'),
        content: Text(
          'This will permanently remove ${service.name} and sync the deletion to Supabase.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await controller.deleteService(service);
    }
  }
}

class _ServiceIdentityCard extends StatelessWidget {
  const _ServiceIdentityCard({required this.service});

  final HouseholdService service;

  @override
  Widget build(BuildContext context) {
    final provider = providerName(service);
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          ServiceIcon(
            icon: service.icon,
            color: service.templateType.color,
            serviceName: service.name,
            templateType: service.templateType,
            size: 52,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Provider: $provider',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  service.templateType.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: service.templateType.color,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ManageSection extends StatelessWidget {
  const _ManageSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: AppSpacing.xs),
          child: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        for (var index = 0; index < children.length; index++) ...[
          children[index],
          if (index < children.length - 1)
            const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}
