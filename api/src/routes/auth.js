const express = require('express');
const router = express.Router();
const { login, activate, refreshToken, getMe } = require('../controllers/authController');
const { authenticateToken } = require('../middleware/auth');
const { supabase } = require('../config/supabase');
const { v4: uuidv4 } = require('uuid');
const { ERROR_CODES, ERROR_MESSAGES } = require('../config/constants');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcrypt');

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

// POST /api/auth/forgot-username
router.post('/forgot-username', async (req, res) => {
  try {
    const { email, phone } = req.body;

    if (!email && !phone) {
      return res.status(400).json({
        success: false,
        error: 'البريد الإلكتروني أو رقم الهاتف مطلوب',
        code: 'VALIDATION_ERROR'
      });
    }

    let query = supabase.from('users').select('username, email, phone');
    
    if (email) {
      query = query.eq('email', email);
    } else if (phone) {
      query = query.eq('phone', phone);
    }

    const { data: users, error } = await query;

    if (error || !users || users.length === 0) {
      return res.status(404).json({
        success: false,
        error: 'لا يوجد حساب مرتبط بهذه المعلومات',
        code: 'NOT_FOUND'
      });
    }

    // في بيئة الإنتاج، نرسل بريد إلكتروني أو رسالة
    // للاختبار، نرجع اسم المستخدم مباشرة
    const usernames = users.map(u => u.username);

    res.json({
      success: true,
      data: {
        message: 'تم إرسال اسم المستخدم إلى بريدك الإلكتروني',
        // للاختبار فقط:
        usernames: process.env.NODE_ENV === 'development' ? usernames : undefined
      },
      message: 'تم إرسال اسم المستخدم إلى بريدك الإلكتروني'
    });
  } catch (error) {
    console.error('خطأ في استعادة اسم المستخدم:', error);
    res.status(500).json({
      success: false,
      error: 'حدث خطأ في الخادم',
      code: 'INTERNAL_ERROR'
    });
  }
});

// POST /api/auth/forgot-password
router.post('/forgot-password', async (req, res) => {
  try {
    const { username, email, phone } = req.body;

    if (!username || (!email && !phone)) {
      return res.status(400).json({
        success: false,
        error: 'اسم المستخدم والبريد الإلكتروني أو رقم الهاتف مطلوب',
        code: 'VALIDATION_ERROR'
      });
    }

    // البحث عن المستخدم
    let query = supabase.from('users').select('id, username, email, phone')
      .eq('username', username);
    
    if (email) {
      query = query.eq('email', email);
    } else if (phone) {
      query = query.eq('phone', phone);
    }

    const { data: user, error } = await query.single();

    if (error || !user) {
      return res.status(404).json({
        success: false,
        error: 'المعلومات غير صحيحة',
        code: 'NOT_FOUND'
      });
    }

    // إنشاء token لإعادة تعيين كلمة المرور (صلاحية ساعة واحدة)
    const jwt = require('jsonwebtoken');
    const resetToken = jwt.sign(
      { user_id: user.id, type: 'password_reset' },
      process.env.JWT_SECRET,
      { expiresIn: '1h' }
    );

    // حفظ token في جدول password_resets
    const { error: insertError } = await supabase
      .from('password_resets')
      .insert({
        id: uuidv4(),
        user_id: user.id,
        token: resetToken,
        expires_at: new Date(Date.now() + 60 * 60 * 1000).toISOString(),
        created_at: new Date().toISOString()
      });

    if (insertError) {
      console.error('خطأ في حفظ token:', insertError);
    }

    // إنشاء رابط إعادة التعيين
    const frontendUrl = process.env.FRONTEND_URL || 'http://localhost:3001';
    const resetUrl = `${frontendUrl}/reset-password?token=${resetToken}`;

    // في بيئة الإنتاج، نرسل بريد إلكتروني
    // للاختبار، نرجع الرابط مباشرة
    if (process.env.NODE_ENV === 'development') {
      return res.json({
        success: true,
        data: {
          resetUrl,
          message: 'رابط إعادة تعيين كلمة المرور (للاختبار فقط)'
        },
        message: `تم إرسال رابط إعادة التعيين إلى ${user.email || 'بريدك الإلكتروني'}` 
      });
    }

    // هنا نضيف إرسال البريد الإلكتروني في الإنتاج
    // await sendEmail(user.email, 'إعادة تعيين كلمة المرور', `اضغط على الرابط: ${resetUrl}`);

    res.json({
      success: true,
      message: 'تم إرسال رابط إعادة تعيين كلمة المرور إلى بريدك الإلكتروني'
    });
  } catch (error) {
    console.error('خطأ في استعادة كلمة المرور:', error);
    res.status(500).json({
      success: false,
      error: 'حدث خطأ في الخادم',
      code: 'INTERNAL_ERROR'
    });
  }
});

// POST /api/auth/reset-password
router.post('/reset-password', async (req, res) => {
  try {
    const { token, new_password } = req.body;

    if (!token || !new_password) {
      return res.status(400).json({
        success: false,
        error: 'الرمز وكلمة المرور الجديدة مطلوبان',
        code: 'VALIDATION_ERROR'
      });
    }

    // التحقق من صحة token
    const jwt = require('jsonwebtoken');
    let decoded;
    try {
      decoded = jwt.verify(token, process.env.JWT_SECRET);
    } catch (err) {
      return res.status(400).json({
        success: false,
        error: 'الرمز غير صالح أو منتهي الصلاحية',
        code: 'INVALID_TOKEN'
      });
    }

    // التحقق من وجود token في جدول password_resets
    const { data: resetRecord, error: resetError } = await supabase
      .from('password_resets')
      .select('*')
      .eq('token', token)
      .eq('user_id', decoded.user_id)
      .single();

    if (resetError || !resetRecord) {
      return res.status(400).json({
        success: false,
        error: 'الرمز غير صالح',
        code: 'INVALID_TOKEN'
      });
    }

    // التحقق من صلاحية token
    if (new Date(resetRecord.expires_at) < new Date()) {
      return res.status(400).json({
        success: false,
        error: 'انتهت صلاحية الرمز',
        code: 'TOKEN_EXPIRED'
      });
    }

    // تشفير كلمة المرور الجديدة
    const bcrypt = require('bcrypt');
    const hashedPassword = await bcrypt.hash(new_password, 10);

    // تحديث كلمة المرور
    const { error: updateError } = await supabase
      .from('users')
      .update({ password_hash: hashedPassword, updated_at: new Date().toISOString() })
      .eq('id', decoded.user_id);

    if (updateError) {
      console.error('خطأ في تحديث كلمة المرور:', updateError);
      throw updateError;
    }

    // حذف token المستخدم
    await supabase
      .from('password_resets')
      .delete()
      .eq('token', token);

    res.json({
      success: true,
      message: 'تم تغيير كلمة المرور بنجاح'
    });
  } catch (error) {
    console.error('خطأ في إعادة تعيين كلمة المرور:', error);
    res.status(500).json({
      success: false,
      error: 'حدث خطأ في الخادم',
      code: 'INTERNAL_ERROR'
    });
  }
});

module.exports = router;
