import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/home_summary.dart';
import '../controllers/ledger_controller.dart';
import '../widgets/loading_skeleton.dart';
import '../widgets/service_contribution_stats.dart';

class ServiceContributionScreen extends StatelessWidget {
  const ServiceContributionScreen({required this.controller, super.key});

  final LedgerController controller;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<HomeServiceSummary>>(
      future: controller.loadHomeServiceSummaries(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return HomeServiceListSkeleton();
        }
        final summaries = snapshot.data ?? const <HomeServiceSummary>[];
        return ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            104,
          ),
          children: [
            Text(
              'Service Spending',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Breakdown of payments made for each service in the selected month.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            ServiceContributionDetailList(summaries: summaries),
          ],
        );
      },
    );
  }
}
