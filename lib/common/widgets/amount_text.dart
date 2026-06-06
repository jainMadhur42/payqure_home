import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/currency_formatter.dart';

class AmountText extends StatelessWidget {
  const AmountText({
    required this.amount,
    this.large = false,
    this.color = AppColors.ink,
    super.key,
  });

  final num amount;
  final bool large;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final style = large
        ? Theme.of(context).textTheme.titleLarge
        : Theme.of(context).textTheme.titleMedium;
    return Text(
      CurrencyFormatter.rupees(amount),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: style?.copyWith(color: color, fontWeight: FontWeight.w900),
    );
  }
}
