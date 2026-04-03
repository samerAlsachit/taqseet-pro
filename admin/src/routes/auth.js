const express = require('express');
const bcrypt = require('bcryptjs');
const { supabase } = require('../config/supabase');
const { generateToken } = require('../utils/auth');

const router = express.Router();

// POST /api/auth/login
router.post('/login', async (req, res) => {
  try {
    const { username, password, is_admin } = req.body;

    if (!username || !password) {
      return res.status(400).json({
        success: false,
        error: 'اسم المستخدم وكلمة المرور مطلوبان'
      });
    }

    // البحث عن المستخدم
    const { data: user, error } = await supabase
      .from('users')
      .select('*')
      .eq('username', username)
      .single();

    if (error || !user) {
      return res.status(401).json({
        success: false,
        error: 'اسم المستخدم أو كلمة المرور غير صحيحة'
      });
    }

    // التحقق من كلمة المرور
    const isValidPassword = await bcrypt.compare(password, user.password);
    if (!isValidPassword) {
      return res.status(401).json({
        success: false,
        error: 'اسم المستخدم أو كلمة المرور غير صحيحة'
      });
    }

    // منع المستخدمين العاديين من تسجيل الدخول إلى Admin Dashboard
    if (is_admin && user.role !== 'super_admin') {
      return res.status(403).json({
        success: false,
        error: 'غير مصرح بالدخول إلى لوحة التحكم',
        code: 'FORBIDDEN'
      });
    }

    // إنشاء التوكن
    const token = generateToken(user);

    res.json({
      success: true,
      data: {
        token,
        user: {
          id: user.id,
          username: user.username,
          full_name: user.full_name,
          role: user.role,
          store_id: user.store_id
        }
      }
    });
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({
      success: false,
      error: 'حدث خطأ في الخادم'
    });
  }
});

// POST /api/auth/register
router.post('/register', async (req, res) => {
  try {
    const { username, password, full_name, phone, store_id } = req.body;

    if (!username || !password || !full_name) {
      return res.status(400).json({
        success: false,
        error: 'جميع الحقول مطلوبة'
      });
    }

    // التحقق من وجود المستخدم
    const { data: existingUser } = await supabase
      .from('users')
      .select('id')
      .eq('username', username)
      .single();

    if (existingUser) {
      return res.status(400).json({
        success: false,
        error: 'اسم المستخدم موجود بالفعل'
      });
    }

    // تشفير كلمة المرور
    const hashedPassword = await bcrypt.hash(password, 10);

    // إنشاء المستخدم
    const { data: newUser, error } = await supabase
      .from('users')
      .insert([
        {
          username,
          password: hashedPassword,
          full_name,
          phone,
          store_id,
          role: 'user'
        }
      ])
      .select()
      .single();

    if (error) {
      return res.status(500).json({
        success: false,
        error: 'فشل في إنشاء المستخدم'
      });
    }

    res.json({
      success: true,
      data: {
        user: {
          id: newUser.id,
          username: newUser.username,
          full_name: newUser.full_name,
          role: newUser.role,
          store_id: newUser.store_id
        }
      }
    });
  } catch (error) {
    console.error('Register error:', error);
    res.status(500).json({
      success: false,
      error: 'حدث خطأ في الخادم'
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
        error: 'جميع الحقول مطلوبة'
      });
    }

    // التحقق من وجود المستخدم
    const { data: existingUser } = await supabase
      .from('users')
      .select('id')
      .eq('username', username)
      .single();

    if (existingUser) {
      return res.status(400).json({
        success: false,
        error: 'اسم المستخدم موجود بالفعل'
      });
    }

    // تشفير كلمة المرور
    const hashedPassword = await bcrypt.hash(password, 10);

    // إنشاء المشرف
    const { data: newAdmin, error } = await supabase
      .from('users')
      .insert([
        {
          username,
          password: hashedPassword,
          full_name,
          phone,
          role: 'super_admin'
        }
      ])
      .select()
      .single();

    if (error) {
      return res.status(500).json({
        success: false,
        error: 'فشل في إنشاء المشرف'
      });
    }

    res.json({
      success: true,
      data: {
        user: {
          id: newAdmin.id,
          username: newAdmin.username,
          full_name: newAdmin.full_name,
          role: newAdmin.role
        }
      }
    });
  } catch (error) {
    console.error('Register super admin error:', error);
    res.status(500).json({
      success: false,
      error: 'حدث خطأ في الخادم'
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
        error: 'البريد الإلكتروني أو رقم الهاتف مطلوب'
      });
    }

    const query = email ? { email } : { phone };
    const { data: user, error } = await supabase
      .from('users')
      .select('username, full_name')
      .or(`email.eq.${email},phone.eq.${phone}`)
      .single();

    if (error || !user) {
      return res.status(404).json({
        success: false,
        error: 'لم يتم العثور على مستخدم بهذه البيانات'
      });
    }

    // هنا يمكن إرسال رسالة بريد إلكتروني أو SMS
    res.json({
      success: true,
      message: `تم إرسال اسم المستخدم إلى ${email || phone}`,
      data: {
        username: user.username,
        full_name: user.full_name
      }
    });
  } catch (error) {
    console.error('Forgot username error:', error);
    res.status(500).json({
      success: false,
      error: 'حدث خطأ في الخادم'
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
        error: 'اسم المستخدم مطلوب'
      });
    }

    const { data: user, error } = await supabase
      .from('users')
      .select('email, phone')
      .eq('username', username)
      .single();

    if (error || !user) {
      return res.status(404).json({
        success: false,
        error: 'لم يتم العثور على مستخدم بهذا الاسم'
      });
    }

    // هنا يمكن إرسال رابط إعادة تعيين كلمة المرور
    res.json({
      success: true,
      message: 'تم إرسال رابط إعادة تعيين كلمة المرور',
      data: {
        email: user.email,
        phone: user.phone
      }
    });
  } catch (error) {
    console.error('Forgot password error:', error);
    res.status(500).json({
      success: false,
      error: 'حدث خطأ في الخادم'
    });
  }
});

module.exports = router;
