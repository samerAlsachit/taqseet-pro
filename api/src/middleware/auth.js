const jwt = require('jsonwebtoken');
const { supabase } = require('../config/supabase');

const authenticateToken = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;
    const token = authHeader && authHeader.split(' ')[1];

    if (!token) {
      return res.status(401).json({
        success: false,
        error: 'غير مصرح، يرجى تسجيل الدخول',
        code: 'UNAUTHORIZED'
      });
    }

    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    req.user = decoded;
    next();
  } catch (error) {
    console.error('خطأ في المصادقة:', error);
    return res.status(401).json({
      success: false,
      error: 'انتهت صلاحية الجلسة أو token غير صالح',
      code: 'UNAUTHORIZED'
    });
  }
};

const requirePermission = (permission) => {
  return (req, res, next) => {
    if (!req.user || !req.user[permission]) {
      return res.status(403).json({
        success: false,
        error: 'غير مصرح بهذه العملية',
        code: 'FORBIDDEN'
      });
    }
    next();
  };
};

const requireSuperAdmin = (req, res, next) => {
  if (!req.user || req.user.role !== 'super_admin') {
    return res.status(403).json({
      success: false,
      error: 'غير مصرح، هذه الصلاحية للمشرفين فقط',
      code: 'FORBIDDEN'
    });
  }
  next();
};

module.exports = {
  auth: authenticateToken,      // <-- إضافة هذا السطر
  authenticateToken,
  requirePermission,
  requireSuperAdmin
};
