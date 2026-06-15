import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../common/widgets/app_logo_mark.dart';
import '../../../../core/app_info/app_compatibility.dart';
import '../../../../core/theme/app_spacing.dart';

class AppUpdateRequiredScreen extends StatelessWidget {
  const AppUpdateRequiredScreen({
    required this.decision,
    required this.onRetry,
    super.key,
  });

  final AppCompatibilityDecision decision;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final appUpdate =
        decision.status == AppCompatibilityStatus.appUpdateRequired;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            children: [
              const Spacer(),
              const AppLogoMark(size: 104),
              const SizedBox(height: AppSpacing.xl),
              Text(
                appUpdate
                    ? 'Update Payqure Home'
                    : 'Service update in progress',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                appUpdate
                    ? 'This version is no longer supported. Update to version '
                          '${decision.config.latestAppVersion} or later to '
                          'continue safely.'
                    : 'This app version needs a newer Payqure database. Please '
                          'try again after the service update is complete.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Installed version ${decision.installedAppVersion}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              if (appUpdate) ...[
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => _openStore(context),
                    icon: const Icon(Icons.system_update_alt),
                    label: const Text('Update App'),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Check Again'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openStore(BuildContext context) async {
    final uri = switch (defaultTargetPlatform) {
      TargetPlatform.android => Uri.parse(
        'https://play.google.com/store/apps/details?id=com.payqure.home',
      ),
      TargetPlatform.iOS => Uri.parse(
        'https://apps.apple.com/us/search?term=Payqure%20Home',
      ),
      _ => Uri.parse(
        'https://play.google.com/store/apps/details?id=com.payqure.home',
      ),
    };
    if (await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      return;
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open the app store. Please try again.'),
        ),
      );
    }
  }
}
