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
