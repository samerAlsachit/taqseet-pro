import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PremiumCurrencyDisplay extends StatelessWidget {
  final double amount;
  final TextStyle? amountStyle;
  final TextStyle? currencyStyle;
  final CrossAxisAlignment alignment;

  const PremiumCurrencyDisplay({
    super.key,
    required this.amount,
    this.amountStyle,
    this.currencyStyle,
    this.alignment = CrossAxisAlignment.end,
  });

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,###');
    final amountText = formatter.format(amount);
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: alignment,
      children: [
        Text(
          amountText,
          style: amountStyle ?? Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontFamily: 'Tajawal',
          ),
        ),
        const SizedBox(width: 4),
        Text(
          'd. a',
          style: currencyStyle ?? Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.white.withValues(alpha: 0.8),
            fontFamily: 'Tajawal',
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
