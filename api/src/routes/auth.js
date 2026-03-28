const express = require('express');
const router = express.Router();
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const { v4: uuidv4 } = require('uuid');
const { supabase, supabaseAdmin } = require('../config/supabase');
const { auth } = require('../middleware/auth');
const { ERROR_CODES, ERROR_MESSAGES } = require('../config/constants');
const { sendPasswordResetEmail, sendUsernameReminder } = require('../services/emailService');

// POST /api/auth/login
router.post('/login', async (req, res) => {
  try {
    const { username, password } = req.body;

    if (!username || !password) {
      return res.status(400).json({
        success: false,
        error: 'اسم المستخدم وكلمة المرور مطلوبان',
        code: 'VALIDATION_ERROR'
      });
    }

    const { data: user, error } = await supabase
      .from('users')
      .select('id, username, password_hash, role, store_id, can_delete, can_edit, can_view_reports')
      .eq('username', username)
      .single();

    if (error || !user) {
      return res.status(401).json({
        success: false,
        error: 'اسم المستخدم أو كلمة المرور غلط',
        code: 'UNAUTHORIZED'
      });
    }

    const isValid = await bcrypt.compare(password, user.password_hash);
    if (!isValid) {
      return res.status(401).json({
        success: false,
        error: 'اسم المستخدم أو كلمة المرور غلط',
        code: 'UNAUTHORIZED'
      });
    }

    const token = jwt.sign(
      {
        user_id: user.id,
        store_id: user.store_id,
        role: user.role,
        can_delete: user.can_delete,
        can_edit: user.can_edit,
        can_view_reports: user.can_view_reports
      },
      process.env.JWT_SECRET,
      { expiresIn: '30d' }
    );

    // تسجيل عملية الدخول في سجل التدقيق
    await supabaseAdmin
      .from('audit_logs')
      .insert({
        id: uuidv4(),
        user_id: user.id,
        store_id: user.store_id,
        action: 'login',
        ip_address: req.ip || req.connection.remoteAddress,
        user_agent: req.get('User-Agent'),
        created_at: new Date().toISOString()
      });

    res.json({
      success: true,
      data: {
        token,
        user: {
          id: user.id,
          username: user.username,
          full_name: user.full_name,
          role: user.role,
          store_id: user.store_id,
          can_delete: user.can_delete,
          can_edit: user.can_edit,
          can_view_reports: user.can_view_reports
        }
      },
      message: 'تم تسجيل الدخول بنجاح'
    });

  } catch (error) {
    console.error('خطأ في تسجيل الدخول:', error);
    res.status(500).json({
      success: false,
      error: 'حدث خطأ في الخادم',
      code: 'INTERNAL_ERROR'
    });
  }
});

// POST /api/auth/activate
router.post('/activate', async (req, res) => {
  try {
    const { code, store_name, owner_name, phone, address, city, username, password } = req.body;

    if (!code || !store_name || !owner_name || !phone || !username || !password) {
      return res.status(400).json({
        success: false,
        error: 'جميع الحقول مطلوبة ما عدا العنوان والمدينة',
        code: 'VALIDATION_ERROR'
      });
    }

    // البحث عن كود التفعيل
    const { data: activationCode, error: codeError } = await supabase
      .from('activation_codes')
      .select('*')
      .eq('code', code)
      .eq('is_used', false)
      .single();

    if (codeError || !activationCode) {
      return res.status(400).json({
        success: false,
        error: 'كود التفعيل غير صالح أو تم استخدامه',
        code: 'VALIDATION_ERROR'
      });
    }

    // التحقق من صلاحية الكود
    const moment = require('moment');
    if (moment(activationCode.expires_at).isBefore(moment())) {
      return res.status(400).json({
        success: false,
        error: 'كود التفعيل منتهي الصلاحية',
        code: 'VALIDATION_ERROR'
      });
    }

    // حساب تواريخ الاشتراك
    const startDate = new Date();
    const trialEndDate = new Date();
    trialEndDate.setDate(trialEndDate.getDate() + 14); // 14 يوم تجريبي
    
    // فترة تجريبية مجانية
    const isTrial = true;
    const trialEnd = trialEndDate.toISOString().split('T')[0];
    
    // إنشاء المحل مع فترة تجريبية
    const { data: newStore, error: storeError } = await supabaseAdmin
      .from('stores')
      .insert({
        name: store_name,
        owner_name: owner_name,
        phone: phone,
        address: address || '',
        city: city || '',
        plan_id: null, // لا يوجد خطة مدفوعة بعد
        subscription_start: startDate.toISOString().split('T')[0],
        subscription_end: trialEnd, // الفترة التجريبية
        trial_end: trialEnd,
        trial_used: true,
        is_active: true,
        default_currency: 'IQD',
        created_at: new Date().toISOString()
      })
      .select()
      .single();

    if (storeError) {
      console.error('خطأ في إنشاء المحل:', storeError);
      return res.status(500).json({
        success: false,
        error: 'فشل في إنشاء المحل',
        code: 'INTERNAL_ERROR'
      });
    }

    // تشفير كلمة المرور
    const hashedPassword = await bcrypt.hash(password, 10);

    // التحقق مما إذا كان المستخدم موجود بالفعل
    const { data: existingUser, error: existingError } = await supabaseAdmin
      .from('users')
      .select('*')
      .eq('store_id', newStore.id)
      .eq('role', 'store_owner')
      .single();

    let user;
    if (existingUser) {
      // تحديث كلمة المرور للمستخدم الموجود
      const { data: updatedUser, error: updateError } = await supabaseAdmin
        .from('users')
        .update({
          username: username,
          full_name: owner_name,
          password_hash: hashedPassword,
          updated_at: new Date().toISOString()
        })
        .eq('id', existingUser.id)
        .select()
        .single();

      if (updateError) {
        console.error('خطأ في تحديث المستخدم:', updateError);
        return res.status(500).json({
          success: false,
          error: 'فشل في تحديث المستخدم',
          code: 'INTERNAL_ERROR'
        });
      }
      user = updatedUser;
    } else {
      // إنشاء مستخدم جديد
      const { data: newUser, error: userError } = await supabaseAdmin
        .from('users')
        .insert({
          store_id: newStore.id,
          full_name: owner_name,
          username: username,
          password_hash: hashedPassword,
          role: 'store_owner',
          can_delete: true,
          can_edit: true,
          can_view_reports: true,
          created_at: new Date().toISOString()
        })
        .select()
        .single();

      if (userError) {
        console.error('خطأ في إنشاء المستخدم:', userError);
        return res.status(500).json({
          success: false,
          error: 'فشل في إنشاء المستخدم',
          code: 'INTERNAL_ERROR'
        });
      }
      user = newUser;
    }

    // تحديث كود التفعيل
    await supabaseAdmin
      .from('activation_codes')
      .update({
        is_used: true,
        used_at: new Date().toISOString(),
        store_id: newStore.id
      })
      .eq('id', activationCode.id);

    // إنشاء JWT token
    const token = jwt.sign(
      {
        user_id: user.id,
        store_id: user.store_id,
        role: user.role,
        can_delete: user.can_delete,
        can_edit: user.can_edit,
        can_view_reports: user.can_view_reports
      },
      process.env.JWT_SECRET,
      { expiresIn: '30d' }
    );

    res.status(201).json({
      success: true,
      data: {
        token,
        store: newStore,
        user: {
          id: user.id,
          username: user.username,
          full_name: user.full_name,
          role: user.role,
          store_id: user.store_id,
          can_delete: user.can_delete,
          can_edit: user.can_edit,
          can_view_reports: user.can_view_reports
        },
        is_trial: true,
        trial_days: 14
      },
      message: 'تم تفعيل المحل بنجاح مع فترة تجريبية لمدة 14 يوم'
    });

  } catch (error) {
    console.error('خطأ في تفعيل الحساب:', error);
    res.status(500).json({
      success: false,
      error: 'حدث خطأ في الخادم',
      code: 'INTERNAL_ERROR'
    });
  }
});

// GET /api/auth/me
router.get('/me', auth, async (req, res) => {
  try {
    const userId = req.user.id || req.user.user_id;
    const storeId = req.user.store_id;

    if (!userId) {
      return res.status(401).json({
        success: false,
        error: 'المستخدم غير مصرح',
        code: 'UNAUTHORIZED'
      });
    }

    const { data: user, error: userError } = await supabase
      .from('users')
      .select('id, username, full_name, role, store_id, can_delete, can_edit, can_view_reports, created_at')
      .eq('id', userId)
      .single();

    if (userError || !user) {
      return res.status(404).json({
        success: false,
        error: 'المستخدم غير موجود',
        code: 'NOT_FOUND'
      });
    }

    let store = null;
    if (storeId) {
      const { data: storeData } = await supabase
        .from('stores')
        .select('id, name, owner_name, phone, address, city, logo_url, receipt_header, receipt_footer, default_currency, subscription_start, subscription_end, is_active, trial_end, plan_id')
        .eq('id', storeId)
        .single();
      store = storeData;
    }

    // حساب أيام الفترة التجريبية المتبقية
    let trialDaysRemaining = null;
    let isTrial = false;
    
    if (store && !store.plan_id && store.trial_end) {
      isTrial = true;
      const trialEnd = new Date(store.trial_end);
      const today = new Date();
      trialDaysRemaining = Math.ceil((trialEnd.getTime() - today.getTime()) / (1000 * 60 * 60 * 24));
    }

    res.json({
      success: true,
      data: {
        user,
        store,
        subscription: {
          days_remaining: store?.subscription_end ? Math.ceil((new Date(store.subscription_end).getTime() - new Date().getTime()) / (1000 * 60 * 60 * 24)) : null,
          expires_at: store?.subscription_end,
          is_active: store?.is_active,
          is_trial: isTrial,
          trial_days_remaining: trialDaysRemaining
        }
      },
      message: 'تم جلب البيانات بنجاح'
    });
  } catch (error) {
    console.error('خطأ في جلب بيانات المستخدم:', error);
    res.status(500).json({
      success: false,
      error: 'حدث خطأ في الخادم',
      code: 'INTERNAL_ERROR'
    });
  }
});

// POST /api/auth/verify-code
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

    if (activationCode.is_used) {
      return res.status(400).json({
        success: false,
        error: 'هذا الكود تم استخدامه مسبقاً',
        code: 'CODE_ALREADY_USED'
      });
    }

    const moment = require('moment');
    if (activationCode.expires_at && moment(activationCode.expires_at).isBefore(moment())) {
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

// POST /api/auth/forgot-password
router.post('/forgot-password', async (req, res) => {
  try {
    const { username } = req.body;

    if (!username) {
      return res.status(400).json({
        success: false,
        error: 'اسم المستخدم مطلوب',
        code: 'VALIDATION_ERROR'
      });
    }

    const { data: user, error } = await supabase
      .from('users')
      .select('id, username, email')
      .eq('username', username)
      .single();

    if (error || !user) {
      return res.status(404).json({
        success: false,
        error: 'اسم المستخدم غير موجود',
        code: 'NOT_FOUND'
      });
    }

    if (!user.email) {
      return res.status(400).json({
        success: false,
        error: 'لا يوجد بريد إلكتروني مرتبط بهذا الحساب',
        code: 'NO_EMAIL'
      });
    }

    const resetToken = jwt.sign(
      { user_id: user.id, type: 'password_reset' },
      process.env.JWT_SECRET,
      { expiresIn: '1h' }
    );

    await supabase
      .from('password_resets')
      .insert({
        id: uuidv4(),
        user_id: user.id,
        token: resetToken,
        expires_at: new Date(Date.now() + 60 * 60 * 1000).toISOString()
      });

    const frontendUrl = process.env.FRONTEND_URL || 'http://localhost:3001';
    const resetUrl = `${frontendUrl}/reset-password?token=${resetToken}`;

    await sendPasswordResetEmail(user.email, user.username, resetUrl);

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

    let decoded;
    try {
      decoded = jwt.verify(token, process.env.JWT_SECRET);
    } catch {
      return res.status(400).json({
        success: false,
        error: 'الرمز غير صالح أو منتهي الصلاحية',
        code: 'INVALID_TOKEN'
      });
    }

    const { data: resetRecord } = await supabase
      .from('password_resets')
      .select('*')
      .eq('token', token)
      .eq('user_id', decoded.user_id)
      .single();

    if (!resetRecord) {
      return res.status(400).json({
        success: false,
        error: 'الرمز غير صالح',
        code: 'INVALID_TOKEN'
      });
    }

    if (new Date(resetRecord.expires_at) < new Date()) {
      return res.status(400).json({
        success: false,
        error: 'انتهت صلاحية الرمز',
        code: 'TOKEN_EXPIRED'
      });
    }

    const hashedPassword = await bcrypt.hash(new_password, 10);

    await supabase
      .from('users')
      .update({ password_hash: hashedPassword, updated_at: new Date().toISOString() })
      .eq('id', decoded.user_id);

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

// POST /api/auth/register-super-admin
router.post('/register-super-admin', async (req, res) => {
  try {
    const { username, password, full_name, phone } = req.body;

    if (!username || !password || !full_name) {
      return res.status(400).json({
        success: false,
        error: 'اسم المستخدم وكلمة المرور والاسم الكامل مطلوبة',
        code: 'VALIDATION_ERROR'
      });
    }

    const { data: existingUser } = await supabase
      .from('users')
      .select('id')
      .eq('username', username)
      .single();

    if (existingUser) {
      return res.status(400).json({
        success: false,
        error: 'اسم المستخدم موجود بالفعل',
        code: 'VALIDATION_ERROR'
      });
    }

    const hashedPassword = await bcrypt.hash(password, 10);

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
        code: 'INTERNAL_ERROR'
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
      error: 'حدث خطأ في الخادم',
      code: 'INTERNAL_ERROR'
    });
  }
});

// POST /api/auth/register-trial
router.post('/register-trial', async (req, res) => {
  try {
    const { store_name, owner_name, phone, address, city, username, password } = req.body;

    if (!store_name || !owner_name || !phone || !username || !password) {
      return res.status(400).json({
        success: false,
        error: 'جميع الحقول المطلوبة يجب أن توفر',
        code: 'VALIDATION_ERROR'
      });
    }

    // التحقق من عدم وجود اسم مستخدم مكرر
    const { data: existingUser } = await supabase
      .from('users')
      .select('id')
      .eq('username', username)
      .single();

    if (existingUser) {
      return res.status(400).json({
        success: false,
        error: 'اسم المستخدم موجود بالفعل',
        code: 'USERNAME_EXISTS'
      });
    }

    // حساب تواريخ الفترة التجريبية (14 يوم)
    const startDate = new Date();
    const trialEndDate = new Date();
    trialEndDate.setDate(trialEndDate.getDate() + 14);
    const trialEnd = trialEndDate.toISOString().split('T')[0];

    // إنشاء المحل مع فترة تجريبية
    const { data: newStore, error: storeError } = await supabase
      .from('stores')
      .insert({
        name: store_name,
        owner_name: owner_name,
        phone: phone,
        address: address || '',
        city: city || '',
        plan_id: null,
        subscription_start: startDate.toISOString().split('T')[0],
        subscription_end: trialEnd,
        trial_end: trialEnd,
        trial_used: true,
        is_active: true,
        default_currency: 'IQD'
      })
      .select()
      .single();

    if (storeError) {
      console.error('خطأ في إنشاء المحل:', storeError);
      return res.status(500).json({
        success: false,
        error: 'فشل في إنشاء المحل',
        code: 'INTERNAL_ERROR'
      });
    }

    // تشفير كلمة المرور
    const hashedPassword = await bcrypt.hash(password, 10);

    // إنشاء المستخدم
    const { data: newUser, error: userError } = await supabase
      .from('users')
      .insert({
        store_id: newStore.id,
        full_name: owner_name,
        username: username,
        password_hash: hashedPassword,
        phone: phone,
        role: 'store_owner',
        can_delete: true,
        can_edit: true,
        can_view_reports: true,
        is_active: true
      })
      .select()
      .single();

    if (userError) {
      console.error('خطأ في إنشاء المستخدم:', userError);
      return res.status(500).json({
        success: false,
        error: 'فشل في إنشاء المستخدم',
        code: 'INTERNAL_ERROR'
      });
    }

    // إنشاء token
    const token = jwt.sign(
      {
        user_id: newUser.id,
        store_id: newStore.id,
        role: newUser.role,
        can_delete: newUser.can_delete,
        can_edit: newUser.can_edit,
        can_view_reports: newUser.can_view_reports
      },
      process.env.JWT_SECRET,
      { expiresIn: '30d' }
    );

    res.json({
      success: true,
      data: {
        token,
        store: newStore,
        user: newUser,
        is_trial: true,
        trial_days: 14
      },
      message: 'تم إنشاء حساب تجريبي لمدة 14 يوم'
    });
  } catch (error) {
    console.error('خطأ في التسجيل التجريبي:', error);
    res.status(500).json({
      success: false,
      error: 'حدث خطأ في الخادم',
      code: 'INTERNAL_ERROR'
    });
  }
});

// POST /api/auth/register-trial
router.post('/register-trial', async (req, res) => {
  try {
    const { store_name, owner_name, phone, address, city, username, password } = req.body;

    if (!store_name || !owner_name || !phone || !username || !password) {
      return res.status(400).json({
        success: false,
        error: 'جميع الحقول المطلوبة يجب أن توفر',
        code: 'VALIDATION_ERROR'
      });
    }

    // التحقق من عدم وجود اسم مستخدم مكرر
    const { data: existingUser } = await supabase
      .from('users')
      .select('id')
      .eq('username', username)
      .single();

    if (existingUser) {
      return res.status(400).json({
        success: false,
        error: 'اسم المستخدم موجود بالفعل',
        code: 'USERNAME_EXISTS'
      });
    }

    // حساب تواريخ الفترة التجريبية (14 يوم)
    const startDate = new Date();
    const trialEndDate = new Date();
    trialEndDate.setDate(trialEndDate.getDate() + 14);
    const trialEnd = trialEndDate.toISOString().split('T')[0];

    // إنشاء المحل مع فترة تجريبية
    const { data: newStore, error: storeError } = await supabase
      .from('stores')
      .insert({
        name: store_name,
        owner_name: owner_name,
        phone: phone,
        address: address || '',
        city: city || '',
        plan_id: null,
        subscription_start: startDate.toISOString().split('T')[0],
        subscription_end: trialEnd,
        trial_end: trialEnd,
        trial_used: true,
        is_active: true,
        default_currency: 'IQD'
      })
      .select()
      .single();

    if (storeError) {
      console.error('خطأ في إنشاء المحل:', storeError);
      return res.status(500).json({
        success: false,
        error: 'فشل في إنشاء المحل',
        code: 'INTERNAL_ERROR'
      });
    }

    // تشفير كلمة المرور
    const bcrypt = require('bcrypt');
    const hashedPassword = await bcrypt.hash(password, 10);

    // إنشاء المستخدم
    const { data: newUser, error: userError } = await supabase
      .from('users')
      .insert({
        store_id: newStore.id,
        full_name: owner_name,
        username: username,
        password_hash: hashedPassword,
        phone: phone,
        role: 'store_owner',
        can_delete: true,
        can_edit: true,
        can_view_reports: true,
        is_active: true
      })
      .select()
      .single();

    if (userError) {
      console.error('خطأ في إنشاء المستخدم:', userError);
      return res.status(500).json({
        success: false,
        error: 'فشل في إنشاء المستخدم',
        code: 'INTERNAL_ERROR'
      });
    }

    // إنشاء token
    const jwt = require('jsonwebtoken');
    const token = jwt.sign(
      {
        user_id: newUser.id,
        store_id: newStore.id,
        role: newUser.role,
        can_delete: newUser.can_delete,
        can_edit: newUser.can_edit,
        can_view_reports: newUser.can_view_reports
      },
      process.env.JWT_SECRET,
      { expiresIn: '30d' }
    );

    res.json({
      success: true,
      data: {
        token,
        store: newStore,
        user: newUser,
        is_trial: true,
        trial_days: 14
      },
      message: 'تم إنشاء حساب تجريبي لمدة 14 يوم'
    });
  } catch (error) {
    console.error('خطأ في التسجيل التجريبي:', error);
    res.status(500).json({
      success: false,
      error: 'حدث خطأ في الخادم',
      code: 'INTERNAL_ERROR'
    });
  }
});

module.exports = router;
