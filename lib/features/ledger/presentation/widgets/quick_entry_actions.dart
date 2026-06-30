import 'package:flutter/material.dart';

import '../../../../common/widgets/app_card.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/household_service.dart';
import '../../domain/entities/service_entry.dart';
import '../../domain/entities/service_template.dart';

class QuickEntryActionCard extends StatefulWidget {
  const QuickEntryActionCard({
    required this.service,
    required this.onQuickMark,
    required this.onCustomize,
    this.customSelectedOverride,
    this.selectedEntry,
    this.selectedStatus,
    super.key,
  });

  final HouseholdService service;
  final bool? customSelectedOverride;
  final ServiceEntry? selectedEntry;
  final ServiceEntryStatus? selectedStatus;
  final ValueChanged<ServiceEntryStatus> onQuickMark;
  final VoidCallback onCustomize;

  @override
  State<QuickEntryActionCard> createState() => _QuickEntryActionCardState();
}

class _QuickEntryActionCardState extends State<QuickEntryActionCard> {
  late ServiceEntryStatus? _selectedStatus;
  late bool _customSelected;

  @override
  void initState() {
    super.initState();
    _synchronizeSelection();
  }

  @override
  void didUpdateWidget(covariant QuickEntryActionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    _synchronizeSelection();
  }

  void _synchronizeSelection() {
    _selectedStatus = widget.selectedStatus ?? widget.selectedEntry?.status;
    _customSelected =
        widget.customSelectedOverride ??
        isCustomQuickEntry(widget.service, widget.selectedEntry);
  }

  void _quickMark(ServiceEntryStatus status) {
    setState(() {
      _selectedStatus = status;
      _customSelected = false;
    });
    widget.onQuickMark(status);
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Log Entry',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: AppSpacing.sm),
          QuickEntryActionGrid(
            service: widget.service,
            customSelectedOverride: _customSelected,
            selectedEntry: widget.selectedEntry,
            selectedStatus: _selectedStatus,
            onQuickMark: _quickMark,
            onCustomize: widget.onCustomize,
          ),
        ],
      ),
    );
  }
}

class QuickEntryActionGrid extends StatelessWidget {
  const QuickEntryActionGrid({
    required this.service,
    required this.onQuickMark,
    this.onCustomize,
    this.customSelectedOverride,
    this.selectedEntry,
    this.selectedStatus,
    this.showCustomize = true,
    this.showNoEntry = false,
    super.key,
  }) : assert(!showCustomize || onCustomize != null);

  final HouseholdService service;
  final bool? customSelectedOverride;
  final ServiceEntry? selectedEntry;
  final ServiceEntryStatus? selectedStatus;
  final bool showCustomize;
  final bool showNoEntry;
  final ValueChanged<ServiceEntryStatus> onQuickMark;
  final VoidCallback? onCustomize;

  @override
  Widget build(BuildContext context) {
    final isAttendance = service.templateType == ServiceTemplateType.attendance;
    final currentStatus = selectedStatus ?? selectedEntry?.status;
    final customSelected =
        showCustomize &&
        (customSelectedOverride ?? isCustomQuickEntry(service, selectedEntry));
    final actions = [
      _QuickEntryAction(
        key: const ValueKey('quick-entry-delivered'),
        label: isAttendance ? 'Present' : 'Delivered',
        semanticsLabel: isAttendance ? 'Mark as present' : 'Mark as delivered',
        icon: Icons.check_rounded,
        color: AppColors.success,
        selected:
            (currentStatus == ServiceEntryStatus.delivered ||
                currentStatus == ServiceEntryStatus.rateChanged) &&
            !customSelected,
        onPressed: () => onQuickMark(ServiceEntryStatus.delivered),
      ),
      _QuickEntryAction(
        key: const ValueKey('quick-entry-not-delivered'),
        label: isAttendance ? 'Absent' : 'Missed',
        semanticsLabel: isAttendance ? 'Mark as absent' : 'Mark as missed',
        icon: Icons.close_rounded,
        color: AppColors.danger,
        selected: currentStatus == ServiceEntryStatus.notDelivered,
        onPressed: () => onQuickMark(ServiceEntryStatus.notDelivered),
      ),
      if (isAttendance)
        _QuickEntryAction(
          key: const ValueKey('quick-entry-half-day'),
          label: 'Half Day',
          semanticsLabel: 'Mark as half day',
          icon: Icons.timelapse_rounded,
          color: AppColors.warning,
          selected: currentStatus == ServiceEntryStatus.halfDay,
          onPressed: () => onQuickMark(ServiceEntryStatus.halfDay),
        ),
      if (showNoEntry)
        _QuickEntryAction(
          key: const ValueKey('quick-entry-no-entry'),
          label: 'No Entry',
          semanticsLabel: 'Mark as no entry',
          icon: Icons.remove_rounded,
          color: AppColors.muted,
          selected: currentStatus == ServiceEntryStatus.noEntry,
          onPressed: () => onQuickMark(ServiceEntryStatus.noEntry),
        ),
      if (showCustomize)
        _QuickEntryAction(
          key: const ValueKey('quick-entry-custom'),
          label: customSelected && selectedEntry != null
              ? 'Custom ${_compactQuantityLabel(selectedEntry!)}'
              : 'Custom',
          semanticsLabel: 'Add custom quantity',
          icon: Icons.edit_rounded,
          color: AppColors.warning,
          selected: customSelected,
          onPressed: onCustomize!,
        ),
    ];

    final rows = _buildRows(actions);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var index = 0; index < rows.length; index++) ...[
          Wrap(
            spacing: 6,
            runSpacing: AppSpacing.xs,
            children: [
              for (final action in rows[index])
                _QuickEntryStatusChip(action: action),
            ],
          ),
          if (index < rows.length - 1) const SizedBox(height: AppSpacing.xs),
        ],
      ],
    );
  }

  List<List<_QuickEntryAction>> _buildRows(List<_QuickEntryAction> actions) {
    return [
      for (var index = 0; index < actions.length; index += 2)
        actions.sublist(
          index,
          index + 2 > actions.length ? actions.length : index + 2,
        ),
    ];
  }

  String _compactQuantityLabel(ServiceEntry entry) {
    final unit = entry.unit.trim();
    if (unit.isEmpty) {
      return entry.quantityLabel;
    }
    final quantityLabel = entry.quantityLabel;
    final separatorIndex = quantityLabel.lastIndexOf(' ');
    final quantity = separatorIndex < 0
        ? quantityLabel
        : quantityLabel.substring(0, separatorIndex);
    return '$quantity ${unit.substring(0, 1).toUpperCase()}';
  }
}

bool isCustomQuickEntry(HouseholdService service, ServiceEntry? entry) {
  if (entry == null ||
      entry.status == ServiceEntryStatus.noEntry ||
      entry.status == ServiceEntryStatus.notDelivered ||
      entry.status == ServiceEntryStatus.halfDay) {
    return false;
  }
  if (service.templateType == ServiceTemplateType.quantity) {
    return (entry.quantity - service.defaultQuantity).abs() > 0.0001;
  }
  return entry.status == ServiceEntryStatus.rateChanged ||
      entry.rateCents != service.rateCents;
}

class _QuickEntryStatusChip extends StatelessWidget {
  const _QuickEntryStatusChip({required this.action});

  final _QuickEntryAction action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final borderColor = action.selected
        ? action.color
        : colorScheme.outlineVariant;
    final backgroundColor = action.selected
        ? action.color.withValues(alpha: 0.12)
        : colorScheme.surface.withValues(alpha: 0.01);
    final textColor = action.selected
        ? action.color
        : colorScheme.onSurfaceVariant;

    return Semantics(
      key: action.key,
      button: true,
      selected: action.selected,
      label: action.semanticsLabel,
      hint: action.selected ? 'Selected' : 'Double tap to select',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: action.onPressed,
          borderRadius: BorderRadius.circular(999),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Ink(
              decoration: ShapeDecoration(
                color: backgroundColor,
                shape: StadiumBorder(side: BorderSide(color: borderColor)),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 36),
                child: Padding(
                  padding: const EdgeInsets.only(left: 3, right: 7),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: action.color,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Icon(action.icon, color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        action.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: textColor,
                          fontWeight: action.selected
                              ? FontWeight.w800
                              : FontWeight.w600,
                        ),
                      ),
                      AnimatedSize(
                        duration: const Duration(milliseconds: 160),
                        curve: Curves.easeOut,
                        child: action.selected
                            ? Padding(
                                padding: const EdgeInsets.only(left: 3),
                                child: Icon(
                                  Icons.check_rounded,
                                  size: 14,
                                  color: action.color,
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickEntryAction {
  const _QuickEntryAction({
    required this.key,
    required this.label,
    required this.semanticsLabel,
    required this.icon,
    required this.color,
    required this.onPressed,
    this.selected = false,
  });

  final Key key;
  final String label;
  final String semanticsLabel;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;
  final bool selected;
}
