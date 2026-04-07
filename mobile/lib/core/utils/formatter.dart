import 'package:intl/intl.dart';

class CurrencyFormatter {
  static String formatCurrency(double amount) {
    final format = NumberFormat('#,###');
    return "${format.format(amount)}  d. a";
  }

  static String formatCurrencyShort(double amount) {
    final format = NumberFormat('#,###');
    return "${format.format(amount)}  d. a";
  }

  static String formatCurrencyWithSymbol(double amount) {
    final format = NumberFormat('#,###');
    return "${format.format(amount)}  d. a";
  }

  // Format for large numbers with K/M suffixes
  static String formatCurrencyCompact(double amount) {
    if (amount >= 1000000) {
      final format = NumberFormat('#,##0.0');
      return "${format.format(amount / 1000000)}M  d. a";
    } else if (amount >= 1000) {
      final format = NumberFormat('#,##0.0');
      return "${format.format(amount / 1000)}K  d. a";
    } else {
      return formatCurrency(amount);
    }
  }

  // Format for display in cards (bold and prominent)
  static String formatCurrencyDisplay(double amount) {
    final format = NumberFormat('#,###');
    return "${format.format(amount)}  d. a";
  }

  // Premium format with smaller currency text
  static String formatCurrencyPremium(double amount) {
    final format = NumberFormat('#,###');
    return "${format.format(amount)}  d. a";
  }
}
