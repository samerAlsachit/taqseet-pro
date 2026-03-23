const jwt = require('jsonwebtoken');
const { ERROR_CODES, ERROR_MESSAGES } = require('../config/constants');

/**
 * middleware للتحقق من توكن JWT المصادقة
 */
const authenticateToken = (req, res, next) => {
  try {
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1]; // Bearer TOKEN

    if (!token) {
      return res.status(401).json({
        success: false,
        error: ERROR_MESSAGES[ERROR_CODES.UNAUTHORIZED],
        code: ERROR_CODES.UNAUTHORIZED
      });
    }

    // التحقق من التوكن
    jwt.verify(token, process.env.JWT_SECRET, (err, decoded) => {
      if (err) {
        let errorCode = ERROR_CODES.INVALID_TOKEN;
        let errorMessage = ERROR_MESSAGES[errorCode];

        if (err.name === 'TokenExpiredError') {
          errorCode = ERROR_CODES.TOKEN_EXPIRED;
          errorMessage = ERROR_MESSAGES[errorCode];
        }

        return res.status(401).json({
          success: false,
          error: errorMessage,
          code: errorCode
        });
      }

      // إضافة بيانات المستخدم للطلب
      req.user = {
        id: decoded.user_id,
        store_id: decoded.store_id,
        role: decoded.role,
        can_delete: decoded.can_delete || false,
        can_edit: decoded.can_edit || false
      };

      next();
    });
  } catch (error) {
    console.error('خطأ في التحقق من التوكن:', error);
    return res.status(500).json({
      success: false,
      error: ERROR_MESSAGES[ERROR_CODES.INTERNAL_ERROR],
      code: ERROR_CODES.INTERNAL_ERROR
    });
  }
};

/**
 * middleware للتحقق من صلاحيات المستخدم
 */
const requirePermission = (permission) => {
  return (req, res, next) => {
    if (!req.user) {
      return res.status(401).json({
        success: false,
        error: ERROR_MESSAGES[ERROR_CODES.UNAUTHORIZED],
        code: ERROR_CODES.UNAUTHORIZED
      });
    }

    // المالك لديه كل الصلاحيات
    if (req.user.role === 'owner') {
      return next();
    }

    // التحقق من الصلاحية المطلوبة
    if (permission === 'delete' && !req.user.can_delete) {
      return res.status(403).json({
        success: false,
        error: ERROR_MESSAGES[ERROR_CODES.INSUFFICIENT_PERMISSIONS],
        code: ERROR_CODES.INSUFFICIENT_PERMISSIONS
      });
    }

    if (permission === 'edit' && !req.user.can_edit) {
      return res.status(403).json({
        success: false,
        error: ERROR_MESSAGES[ERROR_CODES.INSUFFICIENT_PERMISSIONS],
        code: ERROR_CODES.INSUFFICIENT_PERMISSIONS
      });
    }

    next();
  };
};

module.exports = {
  authenticateToken,
  requirePermission
};
