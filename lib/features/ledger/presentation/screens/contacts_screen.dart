import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../common/widgets/selection_card.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/household_service.dart';
import '../../domain/entities/service_template.dart';
import '../widgets/ledger_screen_shared.dart';
import '../widgets/service_icon.dart';

class ContactsScreen extends StatelessWidget {
  const ContactsScreen({required this.services, super.key});

  final List<HouseholdService> services;

  @override
  Widget build(BuildContext context) {
    final contacts = _contacts;
    if (contacts.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          const SizedBox(height: AppSpacing.xl),
          const Icon(
            Icons.contacts_outlined,
            size: 48,
            color: AppColors.primary,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'No service contacts',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Provider contact details will appear here after you add them to a service.',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
          ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        104,
      ),
      children: [
        for (var index = 0; index < contacts.length; index++) ...[
          _ContactCard(contact: contacts[index]),
          if (index != contacts.length - 1)
            const SizedBox(height: AppSpacing.lg),
        ],
      ],
    );
  }

  static int contactCount(List<HouseholdService> services) {
    return _buildContacts(services).length;
  }

  List<_ServiceContact> get _contacts => _buildContacts(services);

  static List<_ServiceContact> _buildContacts(List<HouseholdService> services) {
    final contacts = <String, _ServiceContact>{};
    for (final service in services) {
      final provider = providerName(service);
      final phone = contactNumber(service);
      if (provider == 'Not added' && phone == 'Not added') {
        continue;
      }
      final key = '${provider.toLowerCase()}|${phone.replaceAll(' ', '')}';
      final existing = contacts[key];
      contacts[key] = existing == null
          ? _ServiceContact(
              providerName: provider,
              phoneNumber: phone,
              services: [service],
            )
          : existing.copyWith(services: [...existing.services, service]);
    }
    final result = contacts.values.toList();
    result.sort(
      (a, b) =>
          a.providerName.toLowerCase().compareTo(b.providerName.toLowerCase()),
    );
    return result;
  }
}

class _ContactCard extends StatelessWidget {
  const _ContactCard({required this.contact});

  final _ServiceContact contact;

  @override
  Widget build(BuildContext context) {
    final primaryService = contact.services.first;
    final serviceNames = contact.services
        .map((service) => service.name)
        .join(', ');
    final hasPhone = contact.phoneNumber != 'Not added';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SelectionCard<_ServiceContact>(
      value: contact,
      title: contact.providerName,
      borderColor: isDark ? Colors.black : null,
      leading: ServiceIcon(
        icon: primaryService.icon,
        color: primaryService.templateType.color,
        serviceName: primaryService.name,
        templateType: primaryService.templateType,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            serviceNames,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            contact.phoneNumber,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: hasPhone
                  ? Theme.of(context).colorScheme.onSurface
                  : Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
      onTap: (_) {
        if (hasPhone) {
          _call(context);
        }
      },
      footer: hasPhone
          ? Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _call(context),
                    icon: const Icon(Icons.call_outlined, size: 18),
                    label: const Text('Call'),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _copy(context),
                    icon: const Icon(Icons.content_copy_outlined, size: 18),
                    label: const Text('Copy'),
                  ),
                ),
              ],
            )
          : null,
    );
  }

  Future<void> _call(BuildContext context) async {
    final phone = contact.phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
    final launched = await launchUrl(Uri(scheme: 'tel', path: phone));
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Could not open the phone app.')),
        );
    }
  }

  void _copy(BuildContext context) {
    Clipboard.setData(ClipboardData(text: contact.phoneNumber));
    HapticFeedback.selectionClick();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Phone number copied.')));
  }
}

class _ServiceContact {
  const _ServiceContact({
    required this.providerName,
    required this.phoneNumber,
    required this.services,
  });

  final String providerName;
  final String phoneNumber;
  final List<HouseholdService> services;

  _ServiceContact copyWith({List<HouseholdService>? services}) {
    return _ServiceContact(
      providerName: providerName,
      phoneNumber: phoneNumber,
      services: services ?? this.services,
    );
  }
}
