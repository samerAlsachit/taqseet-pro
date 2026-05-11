import '../config/app_config.dart';

class ApiConstants {
  static String get _base => AppConfig.API_URL;
  static String get login => '$_base/auth/login';
  static String get activate => '$_base/auth/activate';
  static String get registerTrial => '$_base/auth/register-trial';
  static String get me => '$_base/auth/me';
  static String get refresh => '$_base/auth/refresh';
  static String get verifyCode => '$_base/auth/verify-code';
  static String get customers => '$_base/customers';
  static String customer(String id) => '$_base/customers/$id';
  static String get products => '$_base/products';
  static String get installments => '$_base/installments';
  static String installment(String id) => '$_base/installments/$id';
  static String get installmentDueToday => '$_base/installments/due-today';
  static String get payments => '$_base/payments';
  static String get fullSettlement => '$_base/payments/full-settlement';
  static String receipt(String num) => '$_base/payments/receipt/$num';
  static String receiptPrint(String num) => '$_base/payments/receipt/$num/print';
  static String statement(String planId) => '$_base/payments/statement/$planId';
  static String get syncPush => '$_base/sync/push';
  static String get syncPull => '$_base/sync/pull';
  static String get dashboard => '$_base/dashboard';
  static String get dashboardStats => '$_base/dashboard/stats';
  static String get plans => '$_base/plans';
  static String get cashSales => '$_base/cash-sales';
  static String get store => '$_base/store';
}
