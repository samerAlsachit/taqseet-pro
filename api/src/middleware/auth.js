const jwt = require('jsonwebtoken');
const { supabase } = require('../config/supabase');

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
    
    // super_admin ليس لديه store_id، فتخطى التحقق
    if (decoded.role === 'super_admin') {
      req.user = {
        id: decoded.user_id,
        user_id: decoded.user_id,
        store_id: null,
        role: decoded.role,
        can_delete: true,
        can_edit: true,
        can_view_reports: true
      };
      return next();
    }
    
    // للمستخدمين العاديين، تحقق من حالة المحل
    const { data: store, error: storeError } = await supabase
      .from('stores')
      .select('is_active')
      .eq('id', decoded.store_id)
      .single();

    if (storeError || !store) {
      return res.status(403).json({
        success: false,
        error: 'المحل غير موجود',
        code: 'STORE_NOT_FOUND'
      });
    }

    if (!store.is_active) {
      return res.status(403).json({
        success: false,
        error: 'حساب المحل غير نشط. يرجى التواصل مع الدعم.',
        code: 'STORE_INACTIVE'
      });
    }
    
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

// للعمليات التي تسمح بالقراءة فقط حتى لو كان المحل غير نشط
const authReadOnly = async (req, res, next) => {
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
    
    // جلب بيانات المحل للتحقق من حالة النشاط
    const { data: store, error: storeError } = await supabase
      .from('stores')
      .select('is_active')
      .eq('id', decoded.store_id)
      .single();

    if (storeError || !store) {
      return res.status(403).json({
        success: false,
        error: 'المحل غير موجود',
        code: 'STORE_NOT_FOUND'
      });
    }
    
    req.user = {
      id: decoded.user_id,
      user_id: decoded.user_id,
      store_id: decoded.store_id,
      role: decoded.role,
      can_delete: decoded.can_delete,
      can_edit: decoded.can_edit,
      can_view_reports: decoded.can_view_reports,
      store_active: store.is_active
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

module.exports = { auth, requireSuperAdmin, authReadOnly };
