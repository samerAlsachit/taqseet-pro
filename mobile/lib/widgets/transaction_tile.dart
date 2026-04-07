import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/installment_model.dart';
import '../core/utils/formatter.dart';

class TransactionTile extends StatelessWidget {
  final InstallmentModel transaction;
  final VoidCallback? onTap;

  const TransactionTile({super.key, required this.transaction, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Status Icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: transaction.statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getStatusIcon(),
                    color: transaction.statusColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),

                // Customer Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transaction.customerName,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF0A192F),
                          fontFamily: 'Tajawal',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '  ${transaction.formattedDueDate}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF64748B),
                          fontFamily: 'Tajawal',
                        ),
                      ),
                    ],
                  ),
                ),

                // Amount and Status
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      CurrencyFormatter.formatCurrency(
                        transaction.remainingAmount,
                      ),
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0A192F),
                        fontFamily: 'Tajawal',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: transaction.statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        transaction.statusDisplay,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: transaction.statusColor,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Tajawal',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getStatusIcon() {
    switch (transaction.status) {
      case 'completed':
        return LucideIcons.checkCircle;
      case 'pending':
        return LucideIcons.clock;
      case 'overdue':
        return LucideIcons.alertCircle;
      default:
        return LucideIcons.helpCircle;
    }
  }
}
