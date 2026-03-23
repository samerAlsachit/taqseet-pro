import { ERROR_CODES, ERROR_MESSAGES } from '../config/constants';
import { config } from 'dotenv';

// تحميل متغيرات البيئة
config();

/**
 * رسائل الخطأ العربية المخصصة
 */
const ARABIC_ERROR_MESSAGES = {
  // أخطاء المصادقة
  'INVALID_CREDENTIALS': 'اسم المستخدم أو كلمة المرور غير صحيحة',
  'TOKEN_EXPIRED': 'انتهت صلاحية الجلسة، يرجى تسجيل الدخول مرة أخرى',
  'TOKEN_INVALID': 'الجلسة غير صالحة، يرجى تسجيل الدخول مرة أخرى',
  'INSUFFICIENT_PERMISSIONS': 'ليس لديك صلاحية للقيام بهذه العملية',
  'SUBSCRIPTION_EXPIRED': 'انتهى اشتراكك، يرجى التجديد',
  'SUBSCRIPTION_EXPIRING_SOON': 'ينتهي اشتراكك خلال {days} أيام',
  
  // أخطاء التحقق من البيانات
  'VALIDATION_ERROR': 'البيانات المدخلة غير صحيحة',
  'REQUIRED_FIELD': 'الحقل {field} مطلوب',
  'INVALID_EMAIL': 'البريد الإلكتروني غير صحيح',
  'INVALID_PHONE': 'رقم الهاتف غير صحيح',
  'INVALID_DATE': 'التاريخ غير صحيح',
  'INVALID_AMOUNT': 'المبلغ يجب أن يكون رقماً موجباً',
  'PASSWORD_TOO_SHORT': 'كلمة المرور يجب أن تكون 8 أحرف على الأقل',
  'PASSWORDS_NOT_MATCH': 'كلمات المرور غير متطابقة',
  
  // أخطاء قاعدة البيانات
  'DATABASE_ERROR': 'حدث خطأ في قاعدة البيانات',
  'CONNECTION_ERROR': 'فشل الاتصال بقاعدة البيانات',
  'DUPLICATE_ENTRY': 'البيانات موجودة مسبقاً',
  'FOREIGN_KEY_VIOLATION': 'لا يمكن حذف هذا السجل لوجود بيانات مرتبطة به',
  'RECORD_NOT_FOUND': 'السجل غير موجود',
  
  // أخطاء العمل
  'CUSTOMER_NOT_FOUND': 'العميل غير موجود',
  'PRODUCT_NOT_FOUND': 'المنتج غير موجود',
  'STORE_NOT_FOUND': 'المحل غير موجود',
  'INSTALLMENT_PLAN_NOT_FOUND': 'خطة الأقساط غير موجودة',
  'PAYMENT_NOT_FOUND': 'الدفعة غير موجودة',
  'INSUFFICIENT_STOCK': 'الكمية المطلوبة غير متوفرة في المخزون',
  'CANNOT_DELETE_ACTIVE_CUSTOMER': 'لا يمكن حذف زبون لديه أقساط نشطة',
  'CANNOT_DELETE_USED_PRODUCT': 'لا يمكن حذف منتج مستخدم في خطط أقساط نشطة',
  'INSTALLMENT_PLAN_COMPLETED': 'خطة الأقسات مكتملة بالفعل',
  'INSTALLMENT_PLAN_CANCELLED': 'خطة الأقسات ملغاة',
  'PAYMENT_ALREADY_PAID': 'القسط مدفوع بالفعل',
  
  // أخطاء المزامنة
  'SYNC_CONFLICT': 'حدث تعارض في المزامنة',
  'SYNC_FAILED': 'فشلت عملية المزامنة',
  'OFFLINE_MODE': 'أنت في وضع عدم الاتصال',
  'SYNC_IN_PROGRESS': 'عملية المزامنة قيد التنفيذ',
  
  // أخطاء عامة
  'INTERNAL_ERROR': 'حدث خطأ داخلي في الخادم',
  'NETWORK_ERROR': 'فشل الاتصال بالشبكة',
  'TIMEOUT_ERROR': 'انتهت مهلة العملية',
  'RATE_LIMIT_EXCEEDED': 'تجاوزت عدد المحاولات المسموح بها',
  'MAINTENANCE_MODE': 'النظام في وضع الصيانة',
  'FILE_TOO_LARGE': 'حجم الملف كبير جداً',
  'UNSUPPORTED_FILE_TYPE': 'نوع الملف غير مدعوم',
  'QUOTA_EXCEEDED': 'تجاوزت الحد المسموح به',
  
  // أخطاء الأقساط
  'INVALID_INSTALLMENT_AMOUNT': 'مبلغ القسط غير صحيح',
  'INVALID_FREQUENCY': 'تكرار الأقساط غير صحيح',
  'INVALID_DOWN_PAYMENT': 'المقدمة يجب أن تكون أقل من السعر الإجمالي',
  'INSTALLMENT_DATE_IN_PAST': 'تاريخ بدء الأقساط لا يمكن أن يكون في الماضي',
  'INSTALLMENT_PLAN_ALREADY_EXISTS': 'خطة الأقسات موجودة بالفعل',
  
  // أخطاء الدفعات
  'INVALID_PAYMENT_AMOUNT': 'مبلغ الدفعة غير صحيح',
  'PAYMENT_EXCEEDS_AMOUNT': 'مبلغ الدفعة يتجاوز المبلغ المستحق',
  'RECEIPT_NOT_FOUND': 'الوصل غير موجود',
  'PAYMENT_DATE_INVALID': 'تاريخ الدفعة غير صحيح',
  
  // أخطاء التقارير
  'REPORT_GENERATION_FAILED': 'فشل إنشاء التقرير',
  'NO_DATA_AVAILABLE': 'لا توجد بيانات متاحة للتقرير',
  'INVALID_DATE_RANGE': 'نطاق التاريخ غير صحيح',
  'REPORT_FORMAT_UNSUPPORTED': 'تنسيق التقرير غير مدعوم'
};

/**
 * الحصول على رسالة الخطأ العربية
 */
export const getArabicErrorMessage = (errorCode: string, details?: any): string => {
  let message = (ARABIC_ERROR_MESSAGES as any)[errorCode] || ERROR_MESSAGES[errorCode] || 'حدث خطأ غير متوقع';
  
  // استبدال المتغيرات في الرسالة
  if (details) {
    message = message.replace(/{(\w+)}/g, (match: string, key: string) => {
      return details[key] || match;
    });
  }
  
  return message;
};

/**
 * إنشاء خطأ مخصص برسالة عربية
 */
export const createArabicError = (errorCode: string, details?: any) => {
  const message = getArabicErrorMessage(errorCode, details);
  const error = new Error(message);
  (error as any).code = errorCode;
  (error as any).details = details;
  return error;
};

/**
 * معالجة الأخطاء في controllers
 */
export const handleControllerError = (error: any, res: any) => {
  console.error('Controller Error:', error);
  
  // إذا كان الخطأ يحتوي على كود معرف
  if (error.code) {
    const statusCode = getStatusCode(error.code);
    return res.status(statusCode).json({
      success: false,
      error: getArabicErrorMessage(error.code, error.details),
      code: error.code,
      details: error.details || null
    });
  }
  
  // أخطاء قاعدة البيانات
  if (error.code?.startsWith('23')) {
    return handleDatabaseError(error, res);
  }
  
  // أخطاء الشبكة
  if (error.code === 'ECONNREFUSED' || error.code === 'ENOTFOUND') {
    return res.status(503).json({
      success: false,
      error: 'فشل الاتصال بقاعدة البيانات',
      code: 'CONNECTION_ERROR'
    });
  }
  
  // خطأ داخلي افتراضي
  return res.status(500).json({
    success: false,
    error: getArabicErrorMessage('INTERNAL_ERROR'),
    code: 'INTERNAL_ERROR',
    details: (typeof process !== 'undefined' && process.env.NODE_ENV === 'development') ? error.message : null
  });
};

/**
 * معالجة أخطاء قاعدة البيانات
 */
const handleDatabaseError = (error: any, res: any) => {
  switch (error.code) {
    case '23505': // unique_violation
      return res.status(409).json({
        success: false,
        error: getArabicErrorMessage('DUPLICATE_ENTRY'),
        code: 'DUPLICATE_ENTRY'
      });
    
    case '23503': // foreign_key_violation
      return res.status(400).json({
        success: false,
        error: getArabicErrorMessage('FOREIGN_KEY_VIOLATION'),
        code: 'FOREIGN_KEY_VIOLATION'
      });
    
    case '23502': // not_null_violation
      return res.status(400).json({
        success: false,
        error: getArabicErrorMessage('REQUIRED_FIELD'),
        code: 'REQUIRED_FIELD'
      });
    
    default:
      return res.status(500).json({
        success: false,
        error: getArabicErrorMessage('DATABASE_ERROR'),
        code: 'DATABASE_ERROR'
      });
  }
};

/**
 * الحصول على كود HTTP المناسب للخطأ
 */
const getStatusCode = (errorCode: string): number => {
  const statusCodes: { [key: string]: number } = {
    'INVALID_CREDENTIALS': 401,
    'TOKEN_EXPIRED': 401,
    'TOKEN_INVALID': 401,
    'INSUFFICIENT_PERMISSIONS': 403,
    'SUBSCRIPTION_EXPIRED': 403,
    'VALIDATION_ERROR': 400,
    'REQUIRED_FIELD': 400,
    'INVALID_EMAIL': 400,
    'INVALID_PHONE': 400,
    'INVALID_DATE': 400,
    'INVALID_AMOUNT': 400,
    'PASSWORD_TOO_SHORT': 400,
    'PASSWORDS_NOT_MATCH': 400,
    'CUSTOMER_NOT_FOUND': 404,
    'PRODUCT_NOT_FOUND': 404,
    'STORE_NOT_FOUND': 404,
    'INSTALLMENT_PLAN_NOT_FOUND': 404,
    'PAYMENT_NOT_FOUND': 404,
    'RECEIPT_NOT_FOUND': 404,
    'DUPLICATE_ENTRY': 409,
    'INSUFFICIENT_STOCK': 400,
    'CANNOT_DELETE_ACTIVE_CUSTOMER': 400,
    'CANNOT_DELETE_USED_PRODUCT': 400,
    'INSTALLMENT_PLAN_COMPLETED': 400,
    'INSTALLMENT_PLAN_CANCELLED': 400,
    'PAYMENT_ALREADY_PAID': 400,
    'SYNC_CONFLICT': 409,
    'RATE_LIMIT_EXCEEDED': 429,
    'MAINTENANCE_MODE': 503,
    'FILE_TOO_LARGE': 413,
    'UNSUPPORTED_FILE_TYPE': 415,
    'QUOTA_EXCEEDED': 429
  };
  
  return statusCodes[errorCode] || 500;
};

/**
 * التحقق من صحة البيانات مع رسائل خطأ عربية
 */
export const validateWithArabicErrors = (schema: any, data: any) => {
  const { error, value } = schema.validate(data, { abortEarly: false });
  
  if (error) {
    const arabicErrors = error.details.map((detail: any) => {
      const field = detail.path[0];
      const message = getArabicErrorMessage(detail.type, { field });
      return { field, message };
    });
    
    return {
      isValid: false,
      errors: arabicErrors
    };
  }
  
  return {
    isValid: true,
    value
  };
};
