const jwt = require('jsonwebtoken');

const auth = async (req, res, next) => {
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
    
    req.user = {
      id: decoded.user_id,
      user_id: decoded.user_id,
      store_id: decoded.store_id,
      role: decoded.role,
      can_delete: decoded.can_delete,
      can_edit: decoded.can_edit,
      can_view_reports: decoded.can_view_reports
    };
    
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

module.exports = { auth, requireSuperAdmin };
