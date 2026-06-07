import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../common/widgets/app_card.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../ledger/presentation/controllers/ledger_controller.dart';
import '../domain/legal_content.dart';
import '../domain/legal_section.dart';

class PrivacyPolicyView extends StatelessWidget {
  const PrivacyPolicyView({super.key});

  @override
  Widget build(BuildContext context) {
    return const LegalDocumentView(
      title: 'Privacy Policy',
      introduction:
          'This policy explains how Daily Wages handles the information used to manage household services and payments.',
      sections: LegalContent.privacyPolicy,
    );
  }
}

class TermsDisclaimerView extends StatelessWidget {
  const TermsDisclaimerView({super.key});

  @override
  Widget build(BuildContext context) {
    return const LegalDocumentView(
      title: 'Terms & Disclaimer',
      introduction:
          'Please review these terms before using Daily Wages for attendance, wage, and payment records.',
      sections: LegalContent.termsDisclaimer,
    );
  }
}

class LegalDocumentView extends StatelessWidget {
  const LegalDocumentView({
    required this.title,
    required this.introduction,
    required this.sections,
    super.key,
  });

  final String title;
  final String introduction;
  final List<LegalSection> sections;

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
        Text(
          introduction,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            height: 1.5,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        for (final section in sections) ...[
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  section.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  section.body,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(height: 1.55),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }
}

class DeleteMyDataView extends StatelessWidget {
  const DeleteMyDataView({this.registeredIdentifier = '', super.key});

  final String registeredIdentifier;

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
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.delete_forever_outlined,
                color: Theme.of(context).colorScheme.error,
                size: 32,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Request account and data deletion',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: AppSpacing.md),
              const _DeletionPoint(
                text:
                    'Deletion includes service providers, attendance records, payment records, notes, and synchronized account data.',
              ),
              const _DeletionPoint(
                text:
                    'Some records may be retained when required by applicable law.',
              ),
              const _DeletionPoint(
                text:
                    'Deleting your account and associated data may be irreversible.',
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        FilledButton.icon(
          onPressed: () => _requestDeletion(context),
          icon: const Icon(Icons.mail_outline),
          label: const Text('Request Data Deletion'),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextButton.icon(
          onPressed: () => _copySupportEmail(context),
          icon: const Icon(Icons.content_copy_outlined),
          label: const Text('Copy support email'),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          LegalContent.supportEmail,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Future<void> _requestDeletion(BuildContext context) async {
    final body = [
      'Hello,',
      'I would like to request deletion of my Daily Wages account and associated data.',
      '',
      'Registered email/phone: $registeredIdentifier',
      'Reason optional:',
    ].join('\n');
    final uri = Uri(
      scheme: 'mailto',
      path: LegalContent.supportEmail,
      queryParameters: {
        'subject': 'Data Deletion Request - Daily Wages',
        'body': body,
      },
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
      return;
    }
    if (context.mounted) {
      _copySupportEmail(context);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Email app is unavailable. Support email copied.'),
          ),
        );
    }
  }

  void _copySupportEmail(BuildContext context) {
    Clipboard.setData(const ClipboardData(text: LegalContent.supportEmail));
    HapticFeedback.selectionClick();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Support email copied.')));
  }
}

class _DeletionPoint extends StatelessWidget {
  const _DeletionPoint({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 7),
            child: Icon(Icons.circle, size: 6, color: AppColors.primary),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(height: 1.45),
            ),
          ),
        ],
      ),
    );
  }
}

class PrivacyPolicyAcceptanceView extends StatefulWidget {
  const PrivacyPolicyAcceptanceView({required this.controller, super.key});

  final LedgerController controller;

  @override
  State<PrivacyPolicyAcceptanceView> createState() =>
      _PrivacyPolicyAcceptanceViewState();
}

class _PrivacyPolicyAcceptanceViewState
    extends State<PrivacyPolicyAcceptanceView> {
  bool _accepted = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          children: [
            const SizedBox(height: AppSpacing.xxl),
            const Icon(
              Icons.privacy_tip_outlined,
              size: 56,
              color: AppColors.primary,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Privacy Policy Update',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Please review and accept our Privacy Policy to continue using Daily Wages.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            if (widget.controller.errorMessage != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                widget.controller.errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            AppCard(
              child: CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: _accepted,
                onChanged: (value) =>
                    setState(() => _accepted = value ?? false),
                title: const Text(
                  'I have read and agree to the Privacy Policy.',
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            OutlinedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => Scaffold(
                    appBar: AppBar(title: const Text('Privacy Policy')),
                    body: const PrivacyPolicyView(),
                  ),
                ),
              ),
              child: const Text('View Privacy Policy'),
            ),
            const SizedBox(height: AppSpacing.sm),
            FilledButton(
              onPressed: !_accepted || widget.controller.isLoading
                  ? null
                  : widget.controller.acceptPrivacyPolicy,
              child: const Text('Accept & Continue'),
            ),
          ],
        ),
      ),
    );
  }
}
