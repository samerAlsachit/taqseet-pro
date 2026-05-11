class Validators {
  static String? required(String? value, String field) {
    if (value == null || value.trim().isEmpty) return '$field مطلوب';
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final phone = value.replaceAll(RegExp(r'\s+'), '');
    if (phone.length < 10) return 'رقم الهاتف غير صالح';
    return null;
  }

  static String? username(String? value) {
    if (value == null || value.trim().isEmpty) return 'اسم المستخدم مطلوب';
    if (value.length < 3) return 'اسم المستخدم يجب أن يكون 3 أحرف على الأقل';
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.trim().isEmpty) return 'كلمة المرور مطلوبة';
    if (value.length < 6) return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
    return null;
  }

  static String? price(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    if (double.tryParse(value) == null) return 'السعر غير صالح';
    return null;
  }

  static String? code(String? value) {
    if (value == null || value.trim().isEmpty) return 'كود التفعيل مطلوب';
    return null;
  }
}
