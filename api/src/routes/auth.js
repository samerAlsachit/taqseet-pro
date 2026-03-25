const express = require('express');
const router = express.Router();
const { login, activate, refreshToken, getMe } = require('../controllers/authController');
const { authenticateToken } = require('../middleware/auth');
const { supabase } = require('../config/supabase');
const { v4: uuidv4 } = require('uuid');
const { ERROR_CODES, ERROR_MESSAGES } = require('../config/constants');

/**
 * @route   POST /api/auth/login
 * @desc    تسجيل الدخول
 * @access  Public
 */
router.post('/login', login);

/**
 * @route   POST /api/auth/activate
 * @desc    تفعيل الحساب باستخدام كود التفعيل
 * @access  Public
 */
router.post('/activate', activate);

/**
 * @route   POST /api/auth/refresh
 * @desc    تجديد التوكن
 * @access  Public
 */
router.post('/refresh', refreshToken);

/**
 * @route   GET /api/auth/me
 * @desc    جلب بيانات المستخدم الحالي
 * @access  Private
 */
router.get('/me', authenticateToken, getMe);

/**
 * @route   POST /api/auth/verify-code
 * @desc    التحقق من كود التفعيل قبل التفعيل
 * @access  Public
 */
router.post('/verify-code', async (req, res) => {
  try {
    const { code } = req.body;

    if (!code) {
      return res.status(400).json({
        success: false,
        error: 'كود التفعيل مطلوب',
        code: 'VALIDATION_ERROR'
      });
    }

    // البحث عن الكود في قاعدة البيانات
    const { data: activationCode, error } = await supabase
      .from('activation_codes')
      .select('id, plan_id, is_used, expires_at')
      .eq('code', code.toUpperCase())
      .single();

    if (error || !activationCode) {
      return res.status(404).json({
        success: false,
        error: 'الكود غير صالح',
        code: 'NOT_FOUND'
      });
    }

    // التحقق من أن الكود لم يُستخدم
    if (activationCode.is_used) {
      return res.status(400).json({
        success: false,
        error: 'هذا الكود تم استخدامه مسبقاً',
        code: 'CODE_ALREADY_USED'
      });
    }

    // التحقق من صلاحية الكود
    if (activationCode.expires_at && new Date(activationCode.expires_at) < new Date()) {
      return res.status(400).json({
        success: false,
        error: 'انتهت صلاحية الكود',
        code: 'CODE_EXPIRED'
      });
    }

    res.json({
      success: true,
      data: {
        plan_id: activationCode.plan_id,
        is_valid: true
      },
      message: 'الكود صالح'
    });
  } catch (error) {
    console.error('خطأ في التحقق من الكود:', error);
    res.status(500).json({
      success: false,
      error: 'حدث خطأ في الخادم',
      code: 'INTERNAL_ERROR'
    });
  }
});

/**
 * @route   POST /api/auth/register-super-admin
 * @desc    تسجيل سوبر أدمن جديد
 * @access  Public
 */
router.post('/register-super-admin', async (req, res) => {
  try {
    const { username, password, full_name, phone } = req.body;

    // التحقق من المدخلات
    if (!username || !password || !full_name) {
      return res.status(400).json({
        success: false,
        error: 'اسم المستخدم وكلمة المرور والاسم الكامل مطلوبة',
        code: ERROR_CODES.VALIDATION_ERROR
      });
    }

    // التحقق من أن المستخدم غير موجود
    const { data: existingUser } = await supabase
      .from('users')
      .select('id')
      .eq('username', username)
      .single();

    if (existingUser) {
      return res.status(400).json({
        success: false,
        error: 'اسم المستخدم موجود بالفعل',
        code: ERROR_CODES.VALIDATION_ERROR
      });
    }

    // تشفير كلمة المرور
    const bcrypt = require('bcrypt');
    const hashedPassword = await bcrypt.hash(password, 10);

    // إنشاء المستخدم
    const { data: user, error } = await supabase
      .from('users')
      .insert({
        id: uuidv4(),
        store_id: null,
        full_name: full_name,
        username: username,
        password_hash: hashedPassword,
        phone: phone || '',
        role: 'super_admin',
        can_delete: true,
        can_edit: true,
        can_view_reports: true,
        is_active: true,
        created_at: new Date().toISOString()
      })
      .select()
      .single();

    if (error) {
      console.error('خطأ في إنشاء السوبر أدمن:', error);
      return res.status(500).json({
        success: false,
        error: 'فشل في إنشاء المستخدم',
        code: ERROR_CODES.INTERNAL_ERROR
      });
    }

    res.json({
      success: true,
      data: {
        id: user.id,
        username: user.username,
        full_name: user.full_name,
        role: user.role
      },
      message: 'تم إنشاء حساب السوبر أدمن بنجاح'
    });

  } catch (error) {
    console.error('خطأ في تسجيل السوبر أدمن:', error);
    res.status(500).json({
      success: false,
      error: ERROR_MESSAGES[ERROR_CODES.INTERNAL_ERROR],
      code: ERROR_CODES.INTERNAL_ERROR
    });
  }
});

module.exports = router;
