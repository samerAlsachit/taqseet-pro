import 'package:flutter/material.dart';
import '../widgets/premium_currency_display.dart';

class StatCard extends StatelessWidget {
  final String title;
  final double amount;
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;
  final bool isLarge;

  const StatCard({
    super.key,
    required this.title,
    required this.amount,
    required this.icon,
    required this.iconColor,
    this.backgroundColor = const Color(0xFF0A192F),
    this.isLarge = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isLarge ? 24 : 20),
      decoration: BoxDecoration(
        color: isLarge ? backgroundColor : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: isLarge ? 20 : 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isLarge
                      ? Colors.white.withValues(alpha: 0.2)
                      : iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: isLarge ? Colors.white : iconColor,
                  size: isLarge ? 28 : 24,
                ),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isLarge
                  ? Colors.white.withValues(alpha: 0.8)
                  : const Color(0xFF64748B),
              fontFamily: 'Tajawal',
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          if (isLarge)
            PremiumCurrencyDisplay(
              amount: amount,
              amountStyle: Theme.of(context).textTheme.displayMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontFamily: 'Tajawal',
              ),
              currencyStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white.withValues(alpha: 0.8),
                fontFamily: 'Tajawal',
                fontSize: 14,
              ),
            )
          else
            PremiumCurrencyDisplay(
              amount: amount,
              amountStyle: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: const Color(0xFF0A192F),
                fontWeight: FontWeight.bold,
                fontFamily: 'Tajawal',
              ),
              currencyStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: const Color(0xFF64748B),
                fontFamily: 'Tajawal',
                fontSize: 12,
              ),
            ),
        ],
      ),
    );
  }
}
