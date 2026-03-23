const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { supabase, supabaseAdmin } = require('../config/supabase');
const { ERROR_CODES, ERROR_MESSAGES } = require('../config/constants');
const moment = require('moment');
const { v4: uuidv4 } = require('uuid');

// تخزين محاولات الدخول الفاشلة (في الذاكرة - في الإنتاج يجب استخدام Redis)
const failedAttempts = new Map();

/**
 * تسجيل الدخول
 */
const login = async (req, res) => {
  try {
    const { username, password, store_id } = req.body;

    // التحقق من المدخلات
    if (!username || !password) {
      return res.status(400).json({
        success: false,
        error: 'اسم المستخدم وكلمة المرور مطلوبان',
        code: ERROR_CODES.VALIDATION_ERROR
      });
    }

    // التحقق من حماية brute force
    const clientIP = req.ip || req.connection.remoteAddress;
    const attempts = failedAttempts.get(clientIP) || { count: 0, lastAttempt: null };
    
    if (attempts.count >= 5 && Date.now() - attempts.lastAttempt < 15 * 60 * 1000) {
      return res.status(429).json({
        success: false,
        error: 'تم حظر هذا IP مؤقتاً بسبب محاولات دخول متكررة، يرجى المحاولة بعد 15 دقيقة',
        code: 'IP_BLOCKED'
      });
    }

    // البحث عن المستخدم
    let query = supabase
      .from('users')
      .select('*')
      .eq('username', username);

    if (store_id) {
      query = query.eq('store_id', store_id);
    }

    const { data: user, error } = await query.single();

    if (error || !user) {
      // تسجيل المحاولة الفاشلة
      failedAttempts.set(clientIP, {
        count: attempts.count + 1,
        lastAttempt: Date.now()
      });

      return res.status(401).json({
        success: false,
        error: 'اسم المستخدم أو كلمة المرور غلط',
        code: ERROR_CODES.UNAUTHORIZED
      });
    }

    // التحقق من كلمة المرور
    const isPasswordValid = await bcrypt.compare(password, user.password);
    if (!isPasswordValid) {
      // تسجيل المحاولة الفاشلة
      failedAttempts.set(clientIP, {
        count: attempts.count + 1,
        lastAttempt: Date.now()
      });

      return res.status(401).json({
        success: false,
        error: 'اسم المستخدم أو كلمة المرور غلط',
        code: ERROR_CODES.UNAUTHORIZED
      });
    }

    // مسح المحاولات الفاشلة عند النجاح
    failedAttempts.delete(clientIP);

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

    // تسجيل عملية الدخول في سجل التدقيق
    await supabaseAdmin
      .from('audit_logs')
      .insert({
        id: uuidv4(),
        user_id: user.id,
        store_id: user.store_id,
        action: 'login',
        ip_address: clientIP,
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
      error: ERROR_MESSAGES[ERROR_CODES.INTERNAL_ERROR],
      code: ERROR_CODES.INTERNAL_ERROR
    });
  }
};

/**
 * تفعيل الحساب
 */
const activate = async (req, res) => {
  try {
    const { code, store_name, owner_name, phone, address, city } = req.body;

    // التحقق من المدخلات
    if (!code || !store_name || !owner_name || !phone) {
      return res.status(400).json({
        success: false,
        error: 'جميع الحقول مطلوبة ما عدا العنوان والمدينة',
        code: ERROR_CODES.VALIDATION_ERROR
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
        code: ERROR_CODES.VALIDATION_ERROR
      });
    }

    // التحقق من صلاحية الكود
    if (moment(activationCode.expires_at).isBefore(moment())) {
      return res.status(400).json({
        success: false,
        error: 'كود التفعيل منتهي الصلاحية',
        code: ERROR_CODES.VALIDATION_ERROR
      });
    }

    // إنشاء محل جديد
    const { data: store, error: storeError } = await supabaseAdmin
      .from('stores')
      .insert({
        name: store_name,
        owner_name: owner_name,
        phone: phone,
        address: address || '',
        city: city || '',
        subscription_start: moment().toISOString(),
        subscription_end: moment().add(30, 'days').toISOString(), // 30 يوم تجريبية
        created_at: new Date().toISOString()
      })
      .select()
      .single();

    if (storeError) {
      console.error('خطأ في إنشاء المحل:', storeError);
      return res.status(500).json({
        success: false,
        error: 'فشل في إنشاء المحل',
        code: ERROR_CODES.INTERNAL_ERROR
      });
    }

    // تشفير كلمة المرور الافتراضية
    const defaultPassword = '123456'; // يجب إرسالها للمستخدم عبر SMS/Email
    const hashedPassword = await bcrypt.hash(defaultPassword, 10);

    // إنشاء مستخدم owner
    const { data: user, error: userError } = await supabaseAdmin
      .from('users')
      .insert({
        username: owner_name.replace(/\s+/g, '').toLowerCase(), // اسم مستخدم تلقائي
        password: hashedPassword,
        full_name: owner_name,
        role: 'owner',
        store_id: store.id,
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
        code: ERROR_CODES.INTERNAL_ERROR
      });
    }

    // تحديث كود التفعيل
    await supabaseAdmin
      .from('activation_codes')
      .update({
        is_used: true,
        used_at: new Date().toISOString(),
        store_id: store.id
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
        store: {
          id: store.id,
          name: store.name,
          subscription_end: store.subscription_end
        },
        default_password: defaultPassword // للإرسال للمستخدم
      },
      message: 'تم تفعيل الحساب بنجاح'
    });

  } catch (error) {
    console.error('خطأ في تفعيل الحساب:', error);
    res.status(500).json({
      success: false,
      error: ERROR_MESSAGES[ERROR_CODES.INTERNAL_ERROR],
      code: ERROR_CODES.INTERNAL_ERROR
    });
  }
};

/**
 * تجديد التوكن
 */
const refreshToken = async (req, res) => {
  try {
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1];

    if (!token) {
      return res.status(401).json({
        success: false,
        error: ERROR_MESSAGES[ERROR_CODES.UNAUTHORIZED],
        code: ERROR_CODES.UNAUTHORIZED
      });
    }

    // التحقق من التوكن الحالي
    jwt.verify(token, process.env.JWT_SECRET, async (err, decoded) => {
      if (err) {
        return res.status(401).json({
          success: false,
          error: ERROR_MESSAGES[ERROR_CODES.INVALID_TOKEN],
          code: ERROR_CODES.INVALID_TOKEN
        });
      }

      // جلب بيانات المستخدم المحدثة
      const { data: user, error } = await supabase
        .from('users')
        .select('*')
        .eq('id', decoded.user_id)
        .single();

      if (error || !user) {
        return res.status(401).json({
          success: false,
          error: 'المستخدم غير موجود',
          code: ERROR_CODES.NOT_FOUND
        });
      }

      // إنشاء توكن جديد
      const newToken = jwt.sign(
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

      res.json({
        success: true,
        data: {
          token: newToken,
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
        message: 'تم تجديد التوكن بنجاح'
      });
    });

  } catch (error) {
    console.error('خطأ في تجديد التوكن:', error);
    res.status(500).json({
      success: false,
      error: ERROR_MESSAGES[ERROR_CODES.INTERNAL_ERROR],
      code: ERROR_CODES.INTERNAL_ERROR
    });
  }
};

/**
 * جلب بيانات المستخدم الحالي
 */
const getMe = async (req, res) => {
  try {
    const userId = req.user.id;
    const storeId = req.user.store_id;

    // جلب بيانات المستخدم
    const { data: user, error: userError } = await supabase
      .from('users')
      .select('id, username, full_name, role, store_id, can_delete, can_edit, can_view_reports, created_at')
      .eq('id', userId)
      .single();

    if (userError || !user) {
      return res.status(404).json({
        success: false,
        error: 'المستخدم غير موجود',
        code: ERROR_CODES.NOT_FOUND
      });
    }

    // جلب بيانات المحل
    const { data: store, error: storeError } = await supabase
      .from('stores')
      .select('*')
      .eq('id', storeId)
      .single();

    if (storeError || !store) {
      return res.status(404).json({
        success: false,
        error: 'المحل غير موجود',
        code: ERROR_CODES.STORE_NOT_FOUND
      });
    }

    // حساب الأيام المتبقية من الاشتراك
    const now = moment();
    const endDate = moment(store.subscription_end);
    const daysRemaining = endDate.diff(now, 'days');

    res.json({
      success: true,
      data: {
        user,
        store: {
          ...store,
          days_remaining: Math.max(0, daysRemaining)
        }
      },
      message: 'تم جلب البيانات بنجاح'
    });

  } catch (error) {
    console.error('خطأ في جلب بيانات المستخدم:', error);
    res.status(500).json({
      success: false,
      error: ERROR_MESSAGES[ERROR_CODES.INTERNAL_ERROR],
      code: ERROR_CODES.INTERNAL_ERROR
    });
  }
};

module.exports = {
  login,
  activate,
  refreshToken,
  getMe
};
