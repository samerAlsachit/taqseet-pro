// ثوابت المشروع

// رموز الأخطاء الموحدة
const ERROR_CODES = {
  // أخطاء المصادقة
  UNAUTHORIZED: 'UNAUTHORIZED',
  INVALID_TOKEN: 'INVALID_TOKEN',
  TOKEN_EXPIRED: 'TOKEN_EXPIRED',
  
  // أخطاء الاشتراك
  SUBSCRIPTION_EXPIRED: 'SUBSCRIPTION_EXPIRED',
  SUBSCRIPTION_LIMIT_REACHED: 'SUBSCRIPTION_LIMIT_REACHED',
  
  // أخطاء عامة
  VALIDATION_ERROR: 'VALIDATION_ERROR',
  NOT_FOUND: 'NOT_FOUND',
  INTERNAL_ERROR: 'INTERNAL_ERROR',
  RATE_LIMIT_EXCEEDED: 'RATE_LIMIT_EXCEEDED',
  
  // أخطاء خاصة بالأعمال
  STORE_NOT_FOUND: 'STORE_NOT_FOUND',
  CUSTOMER_NOT_FOUND: 'CUSTOMER_NOT_FOUND',
  INSTALLMENT_NOT_FOUND: 'INSTALLMENT_NOT_FOUND',
  PAYMENT_NOT_FOUND: 'PAYMENT_NOT_FOUND',
  INSUFFICIENT_PERMISSIONS: 'INSUFFICIENT_PERMISSIONS'
};

// رسائل الأخطاء بالعربية
const ERROR_MESSAGES = {
  [ERROR_CODES.UNAUTHORIZED]: 'غير مصرح لك بالوصول إلى هذا المورد',
  [ERROR_CODES.INVALID_TOKEN]: 'توكن المصادقة غير صالح',
  [ERROR_CODES.TOKEN_EXPIRED]: 'انتهت صلاحية التوكن، يرجى تسجيل الدخول مرة أخرى',
  [ERROR_CODES.SUBSCRIPTION_EXPIRED]: 'انتهى اشتراكك، يرجى التجديد',
  [ERROR_CODES.SUBSCRIPTION_LIMIT_REACHED]: 'لقد وصلت إلى الحد الأقصى المسموح به في اشتراكك',
  [ERROR_CODES.VALIDATION_ERROR]: 'بيانات المدخلات غير صالحة',
  [ERROR_CODES.NOT_FOUND]: 'المورد المطلوب غير موجود',
  [ERROR_CODES.INTERNAL_ERROR]: 'حدث خطأ داخلي في الخادم',
  [ERROR_CODES.RATE_LIMIT_EXCEEDED]: 'تجاوزت الحد الأقصى للطلبات، يرجى المحاولة لاحقاً',
  [ERROR_CODES.STORE_NOT_FOUND]: 'المحل غير موجود',
  [ERROR_CODES.CUSTOMER_NOT_FOUND]: 'العميل غير موجود',
  [ERROR_CODES.INSTALLMENT_NOT_FOUND]: 'القسط غير موجود',
  [ERROR_CODES.PAYMENT_NOT_FOUND]: 'الدفعة غير موجودة',
  [ERROR_CODES.INSUFFICIENT_PERMISSIONS]: 'لا تملك الصلاحيات الكافية للقيام بهذه العملية'
};

// أدوار المستخدمين
const USER_ROLES = {
  OWNER: 'owner',
  MANAGER: 'manager',
  EMPLOYEE: 'employee'
};

// حالات الاشتراك
const SUBSCRIPTION_STATUS = {
  ACTIVE: 'active',
  EXPIRED: 'expired',
  CANCELLED: 'cancelled',
  SUSPENDED: 'suspended'
};

// حالات الأقساط
const INSTALLMENT_STATUS = {
  PENDING: 'pending',
  PAID: 'paid',
  OVERDUE: 'overdue',
  CANCELLED: 'cancelled'
};

// أولويات العملاء
const CUSTOMER_PRIORITY = {
  LOW: 'low',
  MEDIUM: 'medium',
  HIGH: 'high'
};

module.exports = {
  ERROR_CODES,
  ERROR_MESSAGES,
  USER_ROLES,
  SUBSCRIPTION_STATUS,
  INSTALLMENT_STATUS,
  CUSTOMER_PRIORITY
};
