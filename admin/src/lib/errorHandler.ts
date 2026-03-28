/**
 * رسائل الخطأ العربية لوحة التحكم
 */
const ARABIC_ERROR_MESSAGES = {
  // أخطاء المصادقة
  'INVALID_CREDENTIALS': 'اسم المستخدم أو كلمة المرور غير صحيحة',
  'TOKEN_EXPIRED': 'انتهت صلاحية الجلسة، يرجى تسجيل الدخول مرة أخرى',
  'TOKEN_INVALID': 'الجلسة غير صالحة، يرجى تسجيل الدخول مرة أخرى',
  'INSUFFICIENT_PERMISSIONS': 'ليس لديك صلاحية للقيام بهذه العملية',
  
  // أخطاء الشبكة
  'NETWORK_ERROR': 'فشل الاتصال بالشبكة، يرجى التحقق من اتصالك بالإنترنت',
  'CONNECTION_ERROR': 'فشل الاتصال بالخادم، يرجى المحاولة مرة أخرى',
  'TIMEOUT_ERROR': 'انتهت مهلة الاتصال، يرجى المحاولة مرة أخرى',
  'SERVER_ERROR': 'حدث خطأ في الخادم، يرجى المحاولة لاحقاً',
  
  // أخطاء التحقق من البيانات
  'VALIDATION_ERROR': 'البيانات المدخلة غير صحيحة',
  'REQUIRED_FIELD': 'الحقل {field} مطلوب',
  'INVALID_EMAIL': 'البريد الإلكتروني غير صحيح',
  'INVALID_PHONE': 'رقم الهاتف غير صحيح',
  'INVALID_DATE': 'التاريخ غير صحيح',
  'INVALID_AMOUNT': 'المبلغ يجب أن يكون رقماً موجباً',
  'PASSWORD_TOO_SHORT': 'كلمة المرور يجب أن تكون 8 أحرف على الأقل',
  'PASSWORDS_NOT_MATCH': 'كلمات المرور غير متطابقة',
  
  // أخطاء العمل
  'STORE_NOT_FOUND': 'المحل غير موجود',
  'ACTIVATION_CODE_NOT_FOUND': 'كود التفعيل غير موجود',
  'ACTIVATION_CODE_USED': 'كود التفعيل مستخدم بالفعل',
  'ACTIVATION_CODE_EXPIRED': 'كود التفعيل منتهي الصلاحية',
  'STORE_ALREADY_EXISTS': 'المحل موجود بالفعل',
  
  // أخطاء الإدارة
  'CANNOT_DISABLE_ACTIVE_STORE': 'لا يمكن تعطيل محل نشط لديه مشتركين',
  'CANNOT_DELETE_STORE_WITH_DATA': 'لا يمكن حذف محل لديه بيانات',
  'SUBSCRIPTION_EXTENSION_FAILED': 'فشل تمديد الاشتراك',
  'CODE_GENERATION_FAILED': 'فشل إنشاء أكواد التفعيل',
  
  // أخطاء التقارير
  'REPORT_GENERATION_FAILED': 'فشل إنشاء التقرير',
  'NO_DATA_AVAILABLE': 'لا توجد بيانات متاحة للتقرير',
  'INVALID_DATE_RANGE': 'نطاق التاريخ غير صحيح',
  'EXPORT_FAILED': 'فشل تصدير البيانات',
  
  // أخطاء عامة
  'UNKNOWN_ERROR': 'حدث خطأ غير متوقع',
  'OPERATION_FAILED': 'فشلت العملية، يرجى المحاولة مرة أخرى',
  'DATA_LOADING_FAILED': 'فشل تحميل البيانات، يرجى المحاولة مرة أخرى',
  'SAVE_FAILED': 'فشل حفظ البيانات، يرجى المحاولة مرة أخرى',
  'DELETE_FAILED': 'فشل حذف البيانات، يرجى المحاولة مرة أخرى',
  'UPDATE_FAILED': 'فشل تحديث البيانات، يرجى المحاولة مرة أخرى',
  'UPLOAD_FAILED': 'فشل رفع الملف، يرجى المحاولة مرة أخرى',
  'FILE_TOO_LARGE': 'حجم الملف كبير جداً',
  'UNSUPPORTED_FILE_TYPE': 'نوع الملف غير مدعوم',
  
  // أخطاء المزامنة
  'SYNC_CONFLICT': 'حدث تعارض في المزامنة',
  'SYNC_FAILED': 'فشلت عملية المزامنة',
  'BACKUP_FAILED': 'فشل إنشاء نسخة احتياطية',
  'RESTORE_FAILED': 'فشل استعادة النسخة الاحتياطية'
};

/**
 * الحصول على رسالة الخطأ العربية
 */
export const getArabicErrorMessage = (errorCode: string, details?: any): string => {
  let message = (ARABIC_ERROR_MESSAGES as any)[errorCode] || ARABIC_ERROR_MESSAGES['UNKNOWN_ERROR'];
  
  // استبدال المتغيرات في الرسالة
  if (details) {
    message = message.replace(/{(\w+)}/g, (match: string, key: string) => {
      return details[key] || match;
    });
  }
  
  return message;
};

/**
 * عرض رسالة خطأ للمستخدم
 */
export const showErrorToast = (errorCode: string, details?: any) => {
  const message = getArabicErrorMessage(errorCode, details);
  
  // استخدام toast أو alert حسب availability
  if (typeof window !== 'undefined' && 'toast' in window) {
    (window as any).toast.error(message);
  } else {
    alert(message);
  }
  
  console.error('Error:', { code: errorCode, message, details });
};

/**
 * عرض رسالة نجاح
 */
export const showSuccessToast = (message: string) => {
  // استخدام toast أو alert حسب availability
  if (typeof window !== 'undefined' && 'toast' in window) {
    (window as any).toast.success(message);
  } else {
    alert(message);
  }
};

/**
 * عرض رسالة تحذير
 */
export const showWarningToast = (message: string) => {
  // استخدام toast أو alert حسب availability
  if (typeof window !== 'undefined' && 'toast' in window) {
    (window as any).toast.warning(message);
  } else {
    alert(message);
  }
};

/**
 * معالجة الأخطاء في API calls
 */
export const handleApiError = (error: any): string => {
  console.error('API Error:', error);
  
  // إذا كان الخطأ من API response
  if (error.response) {
    const { data, status } = error.response;
    
    if (data?.code) {
      return getArabicErrorMessage(data.code, data.details);
    }
    
    // رسائل حسب status code
    switch (status) {
      case 401:
        return getArabicErrorMessage('TOKEN_EXPIRED');
      case 403:
        return getArabicErrorMessage('INSUFFICIENT_PERMISSIONS');
      case 404:
        return getArabicErrorMessage('UNKNOWN_ERROR');
      case 409:
        return 'البيانات موجودة مسبقاً';
      case 422:
        return getArabicErrorMessage('VALIDATION_ERROR');
      case 429:
        return 'تجاوزت عدد المحاولات المسموح بها، يرجى المحاولة لاحقاً';
      case 500:
        return getArabicErrorMessage('SERVER_ERROR');
      case 503:
        return getArabicErrorMessage('CONNECTION_ERROR');
      default:
        return getArabicErrorMessage('OPERATION_FAILED');
    }
  }
  
  // إذا كان خطأ شبكة
  if (error.code === 'NETWORK_ERROR' || error.code === 'ECONNREFUSED') {
    return getArabicErrorMessage('NETWORK_ERROR');
  }
  
  if (error.code === 'TIMEOUT') {
    return getArabicErrorMessage('TIMEOUT_ERROR');
  }
  
  // رسالة افتراضية
  return error.message || getArabicErrorMessage('UNKNOWN_ERROR');
};

/**
 * التحقق من صحة النموذج مع رسائل عربية
 */
export const validateForm = (formData: any, rules: { [key: string]: any }): { isValid: boolean; errors: { [key: string]: string } } => {
  const errors: { [key: string]: string } = {};
  
  for (const field in rules) {
    const value = formData[field];
    const fieldRules = rules[field];
    
    // التحقق من الحقل المطلوب
    if (fieldRules.required && (!value || value.toString().trim() === '')) {
      errors[field] = getArabicErrorMessage('REQUIRED_FIELD', { field });
      continue;
    }
    
    // التحقق من البريد الإلكتروني
    if (fieldRules.email && value) {
      const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
      if (!emailRegex.test(value)) {
        errors[field] = getArabicErrorMessage('INVALID_EMAIL');
      }
    }
    
    // التحقق من رقم الهاتف
    if (fieldRules.phone && value) {
      const phoneRegex = /^[\d\s\-\+\(\)]+$/;
      if (!phoneRegex.test(value) || value.length < 10) {
        errors[field] = getArabicErrorMessage('INVALID_PHONE');
      }
    }
    
    // التحقق من المبلغ
    if (fieldRules.amount && value) {
      const amount = parseFloat(value);
      if (isNaN(amount) || amount <= 0) {
        errors[field] = getArabicErrorMessage('INVALID_AMOUNT');
      }
    }
    
    // التحقق من التاريخ
    if (fieldRules.date && value) {
      const date = new Date(value);
      if (isNaN(date.getTime())) {
        errors[field] = getArabicErrorMessage('INVALID_DATE');
      }
    }
    
    // التحقق من طول الحقل
    if (fieldRules.minLength && value && value.length < fieldRules.minLength) {
      errors[field] = `يجب أن يكون الحقل على الأقل ${fieldRules.minLength} أحرف`;
    }
    
    // التحقق من أقصى طول
    if (fieldRules.maxLength && value && value.length > fieldRules.maxLength) {
      errors[field] = `يجب أن لا يتجاوز الحقل ${fieldRules.maxLength} حرف`;
    }
  }
  
  return {
    isValid: Object.keys(errors).length === 0,
    errors
  };
};

/**
 * تنسيق رسالة الخطأ للعرض
 */
export const formatErrorMessage = (error: any): { title: string; message: string; type: 'error' | 'warning' | 'info' | 'success' } => {
  let title = 'خطأ';
  let message = 'حدث خطأ غير متوقع';
  let type: 'error' | 'warning' | 'info' | 'success' = 'error';
  
  if (typeof error === 'string') {
    message = error;
  } else if (error?.message) {
    message = error.message;
  }
  
  // تحديد نوع الخطأ
  if (message.includes('نجح') || message.includes('تم بنجاح')) {
    title = 'نجاح';
    type = 'success';
  } else if (message.includes('تحذير') || message.includes('تنبيه')) {
    title = 'تحذير';
    type = 'warning';
  } else if (message.includes('معلومة') || message.includes('ملاحظة')) {
    title = 'معلومة';
    type = 'info';
  }
  
  return { title, message, type };
};

/**
 * الحصول على لون الحالة
 */
export const getStatusColor = (status: string): string => {
  const colors: { [key: string]: string } = {
    'active': 'text-green-600 bg-green-100',
    'inactive': 'text-red-600 bg-red-100',
    'pending': 'text-yellow-600 bg-yellow-100',
    'completed': 'text-green-600 bg-green-100',
    'cancelled': 'text-red-600 bg-red-100',
    'expired': 'text-gray-600 bg-[var(--bg-primary)]',
    'used': 'text-blue-600 bg-blue-100',
    'unused': 'text-gray-600 bg-[var(--bg-primary)]'
  };
  
  return colors[status] || 'text-gray-600 bg-[var(--bg-primary)]';
};

/**
 * الحصول على نص الحالة بالعربية
 */
export const getStatusText = (status: string): string => {
  const texts: { [key: string]: string } = {
    'active': 'نشط',
    'inactive': 'غير نشط',
    'pending': 'معلق',
    'completed': 'مكتمل',
    'cancelled': 'ملغي',
    'expired': 'منتهي الصلاحية',
    'used': 'مستخدم',
    'unused': 'غير مستخدم',
    'overdue': 'متأخر',
    'paid': 'مدفوع',
    'unpaid': 'غير مدفوع'
  };
  
  return texts[status] || status;
};
