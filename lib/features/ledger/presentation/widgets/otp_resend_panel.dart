import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/otp_request_status.dart';

class OtpResendPanel extends StatefulWidget {
  const OtpResendPanel({
    required this.availableAt,
    required this.status,
    required this.onResend,
    this.isLoading = false,
    this.buttonKey,
    this.showResendButton = true,
    super.key,
  });

  final DateTime? availableAt;
  final OtpRequestStatus? status;
  final Future<void> Function() onResend;
  final bool isLoading;
  final Key? buttonKey;
  final bool showResendButton;

  @override
  State<OtpResendPanel> createState() => _OtpResendPanelState();
}

class _OtpResendPanelState extends State<OtpResendPanel> {
  Timer? _cooldownTimer;

  Duration get _remaining {
    final availableAt = widget.availableAt;
    if (availableAt == null) {
      return Duration.zero;
    }
    final remaining = availableAt.difference(DateTime.now().toUtc());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  Duration get _windowRemaining =>
      widget.status?.remaining(DateTime.now().toUtc()) ?? Duration.zero;

  int get _effectiveUsedCount {
    if (_windowRemaining == Duration.zero) {
      return 0;
    }
    return widget.status?.usedCount ?? 0;
  }

  @override
  void initState() {
    super.initState();
    _startCooldownTicker();
  }

  @override
  void didUpdateWidget(covariant OtpResendPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.availableAt != widget.availableAt ||
        oldWidget.status?.windowResetsAt != widget.status?.windowResetsAt) {
      _startCooldownTicker();
    }
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final remaining = _remaining;
    final windowRemaining = _windowRemaining;
    final limitReached =
        _effectiveUsedCount >= OtpRequestStatus.maximumRequests &&
        windowRemaining > Duration.zero;
    return Column(
      children: [
        if (widget.showResendButton)
          TextButton(
            key: widget.buttonKey,
            onPressed:
                widget.isLoading || remaining > Duration.zero || limitReached
                ? null
                : _resend,
            child: Text(
              remaining > Duration.zero
                  ? 'Resend OTP in ${_formatDuration(remaining)}'
                  : limitReached
                  ? 'OTP request limit reached'
                  : 'Resend OTP',
            ),
          ),
        Text(
          'Maximum 3 otp can be requested per hour and you have used '
          '$_effectiveUsedCount.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        if (windowRemaining > Duration.zero) ...[
          const SizedBox(height: AppSpacing.xs),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.schedule_outlined,
                size: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: AppSpacing.xs),
              Flexible(
                child: Text(
                  'Request limit resets in '
                  '${_formatDuration(windowRemaining, includeHours: true)}',
                  key: const ValueKey('otp-hourly-reset-timer'),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Future<void> _resend() async {
    await widget.onResend();
    if (!mounted) {
      return;
    }
    _startCooldownTicker();
    setState(() {});
  }

  void _startCooldownTicker() {
    _cooldownTimer?.cancel();
    if (_remaining == Duration.zero && _windowRemaining == Duration.zero) {
      return;
    }
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) {
        return;
      }
      if (_remaining == Duration.zero && _windowRemaining == Duration.zero) {
        _cooldownTimer?.cancel();
      }
      setState(() {});
    });
  }

  String _formatDuration(Duration duration, {bool includeHours = false}) {
    final totalSeconds = (duration.inMilliseconds / 1000).ceil();
    final hours = totalSeconds ~/ 3600;
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    if (includeHours) {
      final remainingMinutes = (totalSeconds % 3600) ~/ 60;
      return '${hours.toString().padLeft(2, '0')}:'
          '${remainingMinutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    }
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
