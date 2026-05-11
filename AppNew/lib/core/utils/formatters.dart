import 'package:intl/intl.dart';

class Formatters {
  static final _currencyFormat = NumberFormat('#,###', 'ar');
  static final _dateFormat = DateFormat('yyyy/MM/dd', 'ar');
  static final _dateTimeFormat = DateFormat('yyyy/MM/dd HH:mm', 'ar');

  static String currency(double amount, {String currency = 'IQD'}) {
    return '${_currencyFormat.format(amount)} $currency';
  }

  static String date(DateTime date) => _dateFormat.format(date);
  static String dateTime(DateTime date) => _dateTimeFormat.format(date);

  static String status(String status) {
    switch (status) {
      case 'active': return 'نشط';
      case 'completed': return 'مكتمل';
      case 'overdue': return 'متأخر';
      case 'cancelled': return 'ملغي';
      case 'pending': return 'معلق';
      case 'paid': return 'مدفوع';
      default: return status;
    }
  }

  static String frequency(String freq) {
    switch (freq) {
      case 'daily': return 'يومي';
      case 'weekly': return 'أسبوعي';
      case 'monthly': return 'شهري';
      default: return freq;
    }
  }
}
