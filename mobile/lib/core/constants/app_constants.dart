class AppConstants {
  // App Info
  static const String appName = 'مرساة';
  static const String appVersion = '1.0.0';
  
  // API
  static const String baseUrl = 'http://localhost:3000';
  static const String apiPath = '/api';
  
  // Storage Keys
  static const String tokenKey = 'auth_token';
  static const String themeKey = 'theme_mode';
  static const String userIdKey = 'user_id';
  static const String storeIdKey = 'store_id';
  
  // Database
  static const String databaseName = 'marsa.db';
  static const int databaseVersion = 1;
  
  // Tables
  static const String customersTable = 'customers';
  static const String productsTable = 'products';
  static const String installmentsTable = 'installments';
  static const String paymentsTable = 'payments';
  static const String settingsTable = 'settings';
  
  // Routes
  static const String loginRoute = '/login';
  static const String dashboardRoute = '/dashboard';
  static const String customersRoute = '/customers';
  static const String productsRoute = '/products';
  static const String installmentsRoute = '/installments';
  static const String paymentsRoute = '/payments';
  static const String reportsRoute = '/reports';
  static const String settingsRoute = '/settings';
  
  // Validation
  static const int minPasswordLength = 6;
  static const int maxNameLength = 100;
  static const int maxPhoneLength = 20;
  static const int maxEmailLength = 100;
  
  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;
  
  // Sync
  static const Duration syncInterval = Duration(minutes: 5);
  static const Duration syncTimeout = Duration(seconds: 30);
  
  // UI
  static const double defaultPadding = 16.0;
  static const double cardRadius = 12.0;
  static const double buttonRadius = 8.0;
}

class AppStrings {
  // General
  static const String appName = 'مرساة';
  static const String loading = 'جاري التحميل...';
  static const String error = 'خطأ';
  static const String success = 'نجاح';
  static const String warning = 'تحذير';
  static const String info = 'معلومات';
  static const String ok = 'موافق';
  static const String cancel = 'إلغاء';
  static const String save = 'حفظ';
  static const String delete = 'حذف';
  static const String edit = 'تعديل';
  static const String add = 'إضافة';
  static const String search = 'بحث';
  static const String back = 'رجوع';
  static const String next = 'التالي';
  static const String finish = 'إنهاء';
  static const String yes = 'نعم';
  static const String no = 'لا';
  
  // Auth
  static const String login = 'تسجيل الدخول';
  static const String logout = 'تسجيل الخروج';
  static const String username = 'اسم المستخدم';
  static const String password = 'كلمة المرور';
  static const String rememberMe = 'تذكرني';
  static const String forgotPassword = 'نسيت كلمة المرور؟';
  static const String loginError = 'خطأ في تسجيل الدخول';
  static const String invalidCredentials = 'اسم المستخدم أو كلمة المرور غير صحيحة';
  
  // Dashboard
  static const String dashboard = 'لوحة التحكم';
  static const String totalCustomers = 'إجمالي العملاء';
  static const String activeInstallments = 'الأقساط النشطة';
  static const String todayPayments = 'مدفوعات اليوم';
  static const String overduePayments = 'المدفوعات المتأخرة';
  
  // Customers
  static const String customers = 'العملاء';
  static const String addCustomer = 'إضافة عميل';
  static const String editCustomer = 'تعديل العميل';
  static const String customerName = 'اسم العميل';
  static const String phoneNumber = 'رقم الهاتف';
  static const String address = 'العنوان';
  static const String email = 'البريد الإلكتروني';
  static const String notes = 'ملاحظات';
  static const String customerAdded = 'تم إضافة العميل بنجاح';
  static const String customerUpdated = 'تم تحديث العميل بنجاح';
  static const String customerDeleted = 'تم حذف العميل بنجاح';
  static const String confirmDeleteCustomer = 'هل أنت متأكد من حذف هذا العميل؟';
  
  // Products
  static const String products = 'المنتجات';
  static const String addProduct = 'إضافة منتج';
  static const String editProduct = 'تعديل المنتج';
  static const String productName = 'اسم المنتج';
  static const String description = 'الوصف';
  static const String price = 'السعر';
  static const String costPrice = 'سعر التكلفة';
  static const String quantity = 'الكمية';
  static const String category = 'الفئة';
  static const String minQuantity = 'الحد الأدنى للكمية';
  static const String productAdded = 'تم إضافة المنتج بنجاح';
  static const String productUpdated = 'تم تحديث المنتج بنجاح';
  static const String productDeleted = 'تم حذف المنتج بنجاح';
  static const String confirmDeleteProduct = 'هل أنت متأكد من حذف هذا المنتج؟';
  
  // Installments
  static const String installments = 'الأقساط';
  static const String addInstallment = 'إضافة قسط';
  static const String editInstallment = 'تعديل القسط';
  static const String totalAmount = 'المبلغ الإجمالي';
  static const String downPayment = 'الدفعة الأولى';
  static const String monthlyPayment = 'القسط الشهري';
  static const String months = 'عدد الأشهر';
  static const String startDate = 'تاريخ البدء';
  static const String endDate = 'تاريخ النهاية';
  static const String status = 'الحالة';
  static const String paidAmount = 'المبلغ المدفوع';
  static const String remainingAmount = 'المبلغ المتبقي';
  static const String installmentAdded = 'تم إضافة القسط بنجاح';
  static const String installmentUpdated = 'تم تحديث القسط بنجاح';
  static const String installmentDeleted = 'تم حذف القسط بنجاح';
  static const String confirmDeleteInstallment = 'هل أنت متأكد من حذف هذا القسط؟';
  
  // Payments
  static const String payments = 'الدفعات';
  static const String addPayment = 'إضافة دفعة';
  static const String paymentAmount = 'مبلغ الدفعة';
  static const String paymentDate = 'تاريخ الدفعة';
  static const String paymentMethod = 'طريقة الدفع';
  static const String paymentNotes = 'ملاحظات الدفعة';
  static const String paymentAdded = 'تم إضافة الدفعة بنجاح';
  static const String paymentUpdated = 'تم تحديث الدفعة بنجاح';
  static const String paymentDeleted = 'تم حذف الدفعة بنجاح';
  static const String confirmDeletePayment = 'هل أنت متأكد من حذف هذه الدفعة؟';
  
  // Reports
  static const String reports = 'التقارير';
  static const String salesReport = 'تقرير المبيعات';
  static const String profitReport = 'تقرير الأرباح';
  static const String customerReport = 'تقرير العملاء';
  static const String productReport = 'تقرير المنتجات';
  static const String exportReport = 'تصدير التقرير';
  static const String printReport = 'طباعة التقرير';
  
  // Settings
  static const String settings = 'الإعدادات';
  static const String storeInfo = 'معلومات المتجر';
  static const String storeName = 'اسم المتجر';
  static const String storeAddress = 'عنوان المتجر';
  static const String storePhone = 'هاتف المتجر';
  static const String currency = 'العملة';
  static const String language = 'اللغة';
  static const String theme = 'المظهر';
  static const String syncSettings = 'إعدادات المزامنة';
  static const String autoSync = 'المزامنة التلقائية';
  static const String syncInterval = 'فترة المزامنة';
  static const String backup = 'نسخ احتياطي';
  static const String restore = 'استعادة';
  
  // Status
  static const String active = 'نشط';
  static const String completed = 'مكتمل';
  static const String cancelled = 'ملغي';
  static const String overdue = 'متأخر';
  static const String pending = 'معلق';
  
  // Payment Methods
  static const String cash = 'نقدي';
  static const String card = 'بطاقة';
  static const String bankTransfer = 'تحويل بنكي';
  static const String cheque = 'شيك';
  
  // Categories
  static const String electronics = 'إلكترونيات';
  static const String furniture = 'أثاث';
  static const String clothing = 'ملابس';
  static const String food = 'طعام';
  static const String other = 'أخرى';
}
