import 'package:intl/intl.dart';

class CurrencyFormatter {
  // Currency symbol constant for Iraqi Dinar
  static const String currencySymbol = 'د.ع';

  static String formatCurrency(double amount) {
    final format = NumberFormat('#,###');
    return '${format.format(amount)} $currencySymbol';
  }

  static String formatCurrencyShort(double amount) {
    final format = NumberFormat('#,###');
    return '${format.format(amount)} $currencySymbol';
  }

  static String formatCurrencyWithSymbol(double amount) {
    final format = NumberFormat('#,###');
    return '${format.format(amount)} $currencySymbol';
  }

  // Format for large numbers with K/M suffixes
  static String formatCurrencyCompact(double amount) {
    if (amount >= 1000000) {
      final format = NumberFormat('#,##0.0');
      return '${format.format(amount / 1000000)}M $currencySymbol';
    } else if (amount >= 1000) {
      final format = NumberFormat('#,##0.0');
      return '${format.format(amount / 1000)}K $currencySymbol';
    } else {
      return formatCurrency(amount);
    }
  }

  // Format for display in cards (bold and prominent)
  static String formatCurrencyDisplay(double amount) {
    final format = NumberFormat('#,###');
    return '${format.format(amount)} $currencySymbol';
  }

  // Premium format with smaller currency text
  static String formatCurrencyPremium(double amount) {
    final format = NumberFormat('#,###');
    return '${format.format(amount)} $currencySymbol';
  }
}
