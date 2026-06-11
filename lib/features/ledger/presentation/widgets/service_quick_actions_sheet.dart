import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import 'manage_service_action_tile.dart';

class ServiceQuickActionsSheet extends StatelessWidget {
  const ServiceQuickActionsSheet({
    required this.onRecordPayment,
    required this.onGeneratePdf,
    required this.onManageService,
    super.key,
  });

  final VoidCallback onRecordPayment;
  final VoidCallback onGeneratePdf;
  final VoidCallback onManageService;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(AppRadius.xl),
      ),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Quick Actions',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: AppSpacing.md),
              ManageServiceActionTile(
                icon: Icons.payments_outlined,
                title: 'Record Payment',
                subtitle: 'Settle or record a payment',
                tintColor: AppColors.success,
                onTap: onRecordPayment,
              ),
              const SizedBox(height: AppSpacing.sm),
              ManageServiceActionTile(
                icon: Icons.picture_as_pdf_outlined,
                title: 'Generate PDF',
                subtitle: 'Export monthly statement',
                tintColor: AppColors.primary,
                onTap: onGeneratePdf,
              ),
              const SizedBox(height: AppSpacing.sm),
              ManageServiceActionTile(
                icon: Icons.settings_outlined,
                title: 'Manage Service',
                subtitle: 'More actions and settings',
                tintColor: AppColors.info,
                onTap: onManageService,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
