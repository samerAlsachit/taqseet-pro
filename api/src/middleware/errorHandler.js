const { ERROR_CODES, ERROR_MESSAGES } = require('../config/constants');

/**
 * middleware مركزي لمعالجة الأخطاء
 */
const errorHandler = (err, req, res, next) => {
  console.error('خطأ غير معالج:', err);

  // الخطأ الافتراضي
  let statusCode = 500;
  let errorCode = ERROR_CODES.INTERNAL_ERROR;
  let message = ERROR_MESSAGES[ERROR_CODES.INTERNAL_ERROR];

  // معالجة أنواع مختلفة من الأخطاء
  if (err.name === 'ValidationError') {
    // أخطاء التحقق من Joi
    statusCode = 400;
    errorCode = ERROR_CODES.VALIDATION_ERROR;
    message = err.details ? err.details[0].message : ERROR_MESSAGES[errorCode];
  } else if (err.name === 'JsonWebTokenError') {
    // أخطاء JWT
    statusCode = 401;
    errorCode = ERROR_CODES.INVALID_TOKEN;
    message = ERROR_MESSAGES[errorCode];
  } else if (err.name === 'TokenExpiredError') {
    // انتهاء صلاحية التوكن
    statusCode = 401;
    errorCode = ERROR_CODES.TOKEN_EXPIRED;
    message = ERROR_MESSAGES[errorCode];
  } else if (err.code === '23505') {
    // خطأ تكرار في PostgreSQL
    statusCode = 400;
    errorCode = ERROR_CODES.VALIDATION_ERROR;
    message = 'البيانات المدخلة مكررة';
  } else if (err.code === '23503') {
    // خطأ مفتاح أجنبي في PostgreSQL
    statusCode = 400;
    errorCode = ERROR_CODES.VALIDATION_ERROR;
    message = 'البيانات المرتبطة غير موجودة';
  } else if (err.statusCode) {
    // أخطاء مخصصة مع كود حالة
    statusCode = err.statusCode;
    errorCode = err.code || ERROR_CODES.INTERNAL_ERROR;
    message = err.message || ERROR_MESSAGES[errorCode];
  }

  // في بيئة التطوير، أرسل تفاصيل الخطأ
  const response = {
    success: false,
    error: message,
    code: errorCode
  };

  if (process.env.NODE_ENV === 'development') {
    response.details = err.message;
    response.stack = err.stack;
  }

  res.status(statusCode).json(response);
};

/**
 * middleware للتعامل مع المسارات غير الموجودة
 */
const notFoundHandler = (req, res) => {
  res.status(404).json({
    success: false,
    error: ERROR_MESSAGES[ERROR_CODES.NOT_FOUND],
    code: ERROR_CODES.NOT_FOUND
  });
};

/**
 * دالة مساعدة لإنشاء خطأ مخصص
 */
const createError = (statusCode, code, message) => {
  const error = new Error(message || ERROR_MESSAGES[code]);
  error.statusCode = statusCode;
  error.code = code;
  return error;
};

module.exports = {
  errorHandler,
  notFoundHandler,
  createError
};
