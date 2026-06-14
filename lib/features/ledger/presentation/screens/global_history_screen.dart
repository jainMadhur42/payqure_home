import 'package:flutter/material.dart';

import '../../../../common/widgets/app_card.dart';
import '../../../../common/widgets/app_empty_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/entities/app_route.dart';
import '../../domain/entities/household_service.dart';
import '../../domain/entities/service_history_item.dart';
import '../../domain/entities/service_template.dart';
import '../../domain/services/history_sorter.dart';
import '../controllers/ledger_controller.dart';
import '../widgets/ledger_screen_shared.dart';
import '../widgets/add_advance_bottom_sheet.dart';
import '../widgets/record_payment_bottom_sheet.dart';
import '../widgets/service_icon.dart';
import 'payment_history_screen.dart';

class GlobalHistoryScreen extends StatefulWidget {
  const GlobalHistoryScreen({
    required this.controller,
    required this.type,
    this.service,
    super.key,
  });

  final LedgerController controller;
  final ServiceHistoryType type;
  final HouseholdService? service;

  @override
  State<GlobalHistoryScreen> createState() => _GlobalHistoryScreenState();
}

class _GlobalHistoryScreenState extends State<GlobalHistoryScreen> {
  late Future<List<ServiceHistoryItem>> _future;
  // Last loaded list, kept on screen during a reload so the page doesn't blink.
  List<ServiceHistoryItem> _items = const [];
  bool _loadedOnce = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void didUpdateWidget(covariant GlobalHistoryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.type != widget.type ||
        oldWidget.service?.id != widget.service?.id) {
      _reload();
    }
  }

  Future<List<ServiceHistoryItem>> _load() async {
    final result = switch ((widget.type, widget.service)) {
      (ServiceHistoryType.advance, final HouseholdService _) =>
        await widget.controller.loadSelectedAdvanceHistory(),
      (ServiceHistoryType.advance, null) =>
        await widget.controller.loadGlobalAdvanceHistory(),
      (ServiceHistoryType.payment, _) =>
        await widget.controller.loadGlobalPaymentHistory(),
    };
    if (mounted) {
      _items = result;
      _loadedOnce = true;
    }
    return result;
  }

  void _reload() {
    if (!mounted) return;
    setState(() => _future = _load());
  }

  @override
  Widget build(BuildContext context) {
    final type = widget.type;
    return FutureBuilder<List<ServiceHistoryItem>>(
      future: _future,
      builder: (context, snapshot) {
        if (!_loadedOnce &&
            snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final items = HistorySorter.itemsNewestFirst(snapshot.data ?? _items);
        if (items.isEmpty) {
          return _HistoryEmptyState(type: type);
        }
        if (type == ServiceHistoryType.payment) {
          return _GlobalPaymentHistoryList(
            controller: widget.controller,
            items: items,
            onChanged: _reload,
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.xl,
          ),
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
          itemBuilder: (context, index) => _AdvanceHistoryCard(
            controller: widget.controller,
            item: items[index],
            onChanged: _reload,
          ),
        );
      },
    );
  }
}

class _AdvanceHistoryCard extends StatefulWidget {
  const _AdvanceHistoryCard({
    required this.controller,
    required this.item,
    required this.onChanged,
  });

  final LedgerController controller;
  final ServiceHistoryItem item;
  final VoidCallback onChanged;

  @override
  State<_AdvanceHistoryCard> createState() => _AdvanceHistoryCardState();
}

class _AdvanceHistoryCardState extends State<_AdvanceHistoryCard> {
  static const _actionSize = 50.0;
  static const _maxReveal = (_actionSize * 2) + AppSpacing.md;
  double _revealOffset = 0;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Stack(
        alignment: Alignment.centerRight,
        children: [
          Positioned.fill(
            child: Align(
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _AdvanceActionButton(
                    color: AppColors.primary,
                    icon: Icons.edit_outlined,
                    onTap: _edit,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  _AdvanceActionButton(
                    color: AppColors.danger,
                    icon: Icons.delete_outline,
                    onTap: _delete,
                  ),
                ],
              ),
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            transform: Matrix4.translationValues(_revealOffset, 0, 0),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onHorizontalDragUpdate: (details) {
                setState(() {
                  _revealOffset = (_revealOffset + details.delta.dx).clamp(
                    -_maxReveal,
                    0,
                  );
                });
              },
              onHorizontalDragEnd: (details) {
                final shouldOpen =
                    (details.primaryVelocity ?? 0) < -250 ||
                    _revealOffset.abs() > _maxReveal * 0.42;
                setState(() {
                  _revealOffset = shouldOpen ? -_maxReveal : 0;
                });
              },
              child: ServiceHistoryCard(item: widget.item),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _edit() async {
    final advance = widget.item.advance;
    if (advance == null) {
      return;
    }
    setState(() => _revealOffset = 0);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddAdvanceBottomSheet(
        controller: widget.controller,
        serviceId: widget.item.service.id,
        serviceName: widget.item.service.name,
        month: monthLabelShort(advance.monthKey),
        title: 'Edit Advance',
        advance: advance,
        onSaved: widget.onChanged,
      ),
    );
  }

  Future<void> _delete() async {
    final advance = widget.item.advance;
    if (advance == null) {
      return;
    }
    setState(() => _revealOffset = 0);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Advance?'),
        content: const Text(
          'This will remove the advance and recalculate the related balances.',
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
    if (confirmed != true) {
      return;
    }
    await widget.controller.deleteAdvance(advance);
    widget.onChanged();
  }
}

class _AdvanceActionButton extends StatelessWidget {
  const _AdvanceActionButton({
    required this.color,
    required this.icon,
    required this.onTap,
  });

  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 50,
      height: 50,
      child: Material(
        color: color,
        shape: const CircleBorder(),
        child: IconButton(
          onPressed: onTap,
          color: Colors.white,
          icon: Icon(icon),
        ),
      ),
    );
  }
}

class _GlobalPaymentHistoryList extends StatelessWidget {
  const _GlobalPaymentHistoryList({
    required this.controller,
    required this.items,
    required this.onChanged,
  });

  final LedgerController controller;
  final List<ServiceHistoryItem> items;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final grouped = <String, List<ServiceHistoryItem>>{};
    for (final item in items) {
      final monthKey = monthKeyForDate(item.date);
      grouped.putIfAbsent(monthKey, () => []).add(item);
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      children: [
        ...grouped.entries.map(
          (entry) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  monthLabelShort(entry.key),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                ...entry.value.map((item) {
                  final payment = item.payment;
                  if (payment == null) {
                    return ServiceHistoryCard(item: item);
                  }
                  return PaymentHistoryCard(
                    service: item.service,
                    payment: payment,
                    showServiceName: true,
                    onEdit: () =>
                        _showEditPaymentSheet(context, serviceItem: item),
                    onDelete: () => _deletePayment(item),
                  );
                }),
              ],
            ),
          ),
        ),
        const _SecurePaymentsCard(),
      ],
    );
  }

  Future<void> _showEditPaymentSheet(
    BuildContext context, {
    required ServiceHistoryItem serviceItem,
  }) async {
    final payment = serviceItem.payment;
    if (payment == null) {
      return;
    }
    controller.trackRecordPaymentStarted(
      service: serviceItem.service,
      source: 'global_payment_history',
    );
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RecordPaymentBottomSheet(
        controller: controller,
        service: serviceItem.service,
        payment: payment,
        source: 'global_payment_history',
        returnRoute: LedgerRoute.globalPaymentHistory,
      ),
    );
    onChanged();
  }

  Future<void> _deletePayment(ServiceHistoryItem item) async {
    final payment = item.payment;
    if (payment == null) {
      return;
    }
    await controller.deletePayment(
      payment,
      service: item.service,
      source: 'global_payment_history',
      returnRoute: LedgerRoute.globalPaymentHistory,
    );
    onChanged();
  }
}

class _SecurePaymentsCard extends StatelessWidget {
  const _SecurePaymentsCard();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.lock_outline,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              'All payments are securely stored and synced across your devices.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ServiceHistoryCard extends StatelessWidget {
  const ServiceHistoryCard({required this.item, super.key});

  final ServiceHistoryItem item;

  @override
  Widget build(BuildContext context) {
    final service = item.service;
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ServiceIcon(
            icon: service.icon,
            color: service.templateType.color,
            serviceName: service.name,
            templateType: service.templateType,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        service.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      CurrencyFormatter.rupees(item.amountCents / 100),
                      maxLines: 1,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${item.modeLabel} · ${_dateLabel(item.date)}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                if (item.note.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    item.note,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                if (item.pendingSync) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Pending sync',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.warning,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _dateLabel(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

class _HistoryEmptyState extends StatelessWidget {
  const _HistoryEmptyState({required this.type});

  final ServiceHistoryType type;

  @override
  Widget build(BuildContext context) {
    final isPayment = type == ServiceHistoryType.payment;
    return AppEmptyState(
      icon: isPayment
          ? Icons.account_balance_wallet_outlined
          : Icons.savings_outlined,
      title: isPayment ? 'No payments yet' : 'No advances yet',
    );
  }
}
