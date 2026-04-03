const express = require('express');
const { supabase, supabaseAdmin } = require('../config/supabase');
const { ERROR_CODES, ERROR_MESSAGES } = require('../config/constants');
const moment = require('moment');
const { v4: uuidv4 } = require('uuid');
const bcrypt = require('bcrypt');
const { auth, requireSuperAdmin } = require('../middleware/auth');
const { logAudit } = require('../middleware/audit');

const router = express.Router();

// Apply authentication middleware to all admin routes
router.use(auth);

/**
 * GET /api/admin/stats
 * جلب إحصائيات عامة للنظام
 */
router.get('/stats', auth, requireSuperAdmin, async (req, res) => {
  try {
    console.log('=== Admin Stats Endpoint ===');
    console.log('User:', req.user);
    console.log('Role:', req.user?.role);

    if (req.user?.role !== 'super_admin') {
      console.log('User is not super_admin, returning empty');
      return res.json({
        success: true,
        data: {
          totalStores: 0,
          activeStores: 0,
          expiringSoon: 0,
          newStoresThisMonth: 0,
          totalUsers: 0,
          totalInstallments: 0,
          totalRevenue: { IQD: 0, USD: 0 }
        }
      });
    }

    // إجمالي المحلات
    const { count: totalStores } = await supabase
      .from('stores')
      .select('*', { count: 'exact', head: true });

    // المحلات النشطة
    const { count: activeStores } = await supabase
      .from('stores')
      .select('*', { count: 'exact', head: true })
      .eq('is_active', true);

    // المحلات التي تنتهي اشتراكها خلال 7 أيام
    const { count: expiringSoon } = await supabase
      .from('stores')
      .select('*', { count: 'exact', head: true })
      .lt('subscription_end', new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString())
      .gte('subscription_end', new Date().toISOString());

    // المحلات الجديدة هذا الشهر
    const firstDayOfMonth = new Date();
    firstDayOfMonth.setDate(1);
    firstDayOfMonth.setHours(0, 0, 0, 0);

    const { count: newStoresThisMonth } = await supabase
      .from('stores')
      .select('*', { count: 'exact', head: true })
      .gte('created_at', firstDayOfMonth.toISOString());

    res.json({
      success: true,
      data: {
        total_stores: totalStores || 0,
        active_stores: activeStores || 0,
        expiring_soon: expiringSoon || 0,
        new_stores_this_month: newStoresThisMonth || 0,
        total_revenue: 0
      },
      message: 'تم جلب الإحصائيات بنجاح'
    });
  } catch (error) {
    console.error('خطأ:', error);
    res.status(500).json({ success: false, error: 'خطأ في الخادم' });
  }
});

/**
 * GET /api/admin/stores
 * جلب قائمة المحلات مع الفلاتر
 */
router.get('/stores', async (req, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 20;
    const offset = (page - 1) * limit;
    const search = req.query.search || '';
    const status = req.query.status;

    let query = supabase
      .from('stores')
      .select(`
        *,
        subscription_plans!stores_plan_id_fkey (name)
      `, { count: 'exact' });

    if (search) {
      query = query.or(`name.ilike.%${search}%,owner_name.ilike.%${search}%,phone.ilike.%${search}%`);
    }

    if (status === 'active') {
      query = query.eq('is_active', true);
    } else if (status === 'expired') {
      query = query.lt('subscription_end', new Date().toISOString());
    }

    const { data: stores, error, count } = await query
      .range(offset, offset + limit - 1)
      .order('created_at', { ascending: false });

    if (error) {
      console.error('خطأ في جلب المحلات:', error);
      throw error;
    }

    const formattedStores = stores.map(store => ({
      id: store.id,
      name: store.name,
      owner_name: store.owner_name,
      phone: store.phone,
      city: store.city,
      plan_name: store.subscription_plans?.name || 'بدون خطة',
      subscription_end: store.subscription_end,
      is_active: store.is_active,
      created_at: store.created_at
    }));

    res.json({
      success: true,
      data: {
        stores: formattedStores,
        pagination: {
          page,
          limit,
          total: count || 0,
          totalPages: Math.ceil((count || 0) / limit)
        }
      },
      message: 'تم جلب المحلات بنجاح'
    });
  } catch (error) {
    console.error('خطأ في جلب المحلات:', error);
    res.status(500).json({
      success: false,
      error: ERROR_MESSAGES[ERROR_CODES.INTERNAL_ERROR],
      code: ERROR_CODES.INTERNAL_ERROR
    });
  }
});

/**
 * GET /api/admin/activation-codes
 * جلب قائمة كودات التفعيل
 */
router.get('/activation-codes', async (req, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 20;
    const offset = (page - 1) * limit;
    const status = req.query.status || 'all';

    let query = supabase
      .from('activation_codes')
      .select('*', { count: 'exact' });

    if (status === 'used') {
      query = query.eq('is_used', true);
    } else if (status === 'unused') {
      query = query.eq('is_used', false);
    }

    const { data: codes, error, count } = await query
      .range(offset, offset + limit - 1)
      .order('created_at', { ascending: false });

    if (error) throw error;

    const formattedCodes = await Promise.all((codes || []).map(async (code) => {
      let planName = null;
      let storeName = null;

      if (code.plan_id) {
        const { data: plan } = await supabase
          .from('subscription_plans')
          .select('name')
          .eq('id', code.plan_id)
          .single();
        planName = plan?.name;
      }

      if (code.store_id) {
        const { data: store } = await supabase
          .from('stores')
          .select('name')
          .eq('id', code.store_id)
          .single();
        storeName = store?.name;
      }

      return {
        id: code.id,
        code: code.code,
        plan_id: code.plan_id,
        plan_name: planName,
        duration_days: code.duration_days,
        is_used: code.is_used,
        used_at: code.used_at,
        store_id: code.store_id,
        store_name: storeName,
        notes: code.notes,
        created_at: code.created_at
      };
    }));

    res.json({
      success: true,
      data: {
        codes: formattedCodes,
        pagination: {
          page,
          limit,
          total: count || 0,
          totalPages: Math.ceil((count || 0) / limit)
        }
      },
      message: 'تم جلب الكودات بنجاح'
    });
  } catch (error) {
    console.error('خطأ في جلب الكودات:', error);
    res.status(500).json({
      success: false,
      error: ERROR_MESSAGES[ERROR_CODES.INTERNAL_ERROR],
      code: ERROR_CODES.INTERNAL_ERROR
    });
  }
});

/**
 * GET /api/admin/subscription-plans
 * جلب خطط الاشتراك
 */
router.get('/subscription-plans', async (req, res) => {
  try {
    const { data: plans, error } = await supabase
      .from('subscription_plans')
      .select('*')
      .eq('is_active', true)
      .order('duration_days');

    if (error) throw error;

    res.json({
      success: true,
      data: plans,
      message: 'تم جلب الخطط بنجاح'
    });
  } catch (error) {
    console.error('خطأ في جلب الخطط:', error);
    res.status(500).json({
      success: false,
      error: ERROR_MESSAGES[ERROR_CODES.INTERNAL_ERROR],
      code: ERROR_CODES.INTERNAL_ERROR
    });
  }
});

/**
 * POST /api/admin/activation-codes
 * إنشاء كودات تفعيل جديدة
 */
router.post('/activation-codes', async (req, res) => {
  try {
    const { plan_id, quantity = 1, notes } = req.body;

    if (!plan_id) {
      return res.status(400).json({
        success: false,
        error: 'الخطة مطلوبة',
        code: ERROR_CODES.VALIDATION_ERROR
      });
    }

    const { data: plan, error: planError } = await supabase
      .from('subscription_plans')
      .select('duration_days, name')
      .eq('id', plan_id)
      .single();

    if (planError || !plan) {
      return res.status(404).json({
        success: false,
        error: 'الخطة غير موجودة',
        code: ERROR_CODES.NOT_FOUND
      });
    }

    const codes = [];
    const generateCode = () => {
      const prefix = 'TQST';
      const random = Math.random().toString(36).substring(2, 6).toUpperCase();
      const random2 = Math.random().toString(36).substring(2, 6).toUpperCase();
      return `${prefix}-${random}-${random2}`;
    };

    for (let i = 0; i < quantity; i++) {
      const code = generateCode();
      codes.push({
        id: uuidv4(),
        code,
        plan_id,
        duration_days: plan.duration_days,
        notes: notes || null,
        created_at: new Date().toISOString()
      });
    }

    const { data: insertedCodes, error: insertError } = await supabase
      .from('activation_codes')
      .insert(codes)
      .select();

    if (insertError) {
      console.error('خطأ في إنشاء الكودات:', insertError);
      throw insertError;
    }

    res.json({
      success: true,
      data: insertedCodes,
      message: `تم إنشاء ${quantity} كود بنجاح`
    });
  } catch (error) {
    console.error('خطأ في إنشاء الكودات:', error);
    res.status(500).json({
      success: false,
      error: ERROR_MESSAGES[ERROR_CODES.INTERNAL_ERROR],
      code: ERROR_CODES.INTERNAL_ERROR
    });
  }
});

/**
 * POST /api/admin/stores/:id/extend
 * تمديد اشتراك محل
 */
router.post('/stores/:id/extend', async (req, res) => {
  try {
    const { id } = req.params;
    const { additional_days, plan_id } = req.body;

    if (!additional_days && !plan_id) {
      return res.status(400).json({
        success: false,
        error: 'عدد الأيام أو الخطة الجديدة مطلوب',
        code: ERROR_CODES.VALIDATION_ERROR
      });
    }

    const { data: store, error: storeError } = await supabase
      .from('stores')
      .select('subscription_end, plan_id, name')
      .eq('id', id)
      .single();

    if (storeError || !store) {
      return res.status(404).json({
        success: false,
        error: 'المحل غير موجود',
        code: ERROR_CODES.NOT_FOUND
      });
    }

    let currentEndDate = new Date(store.subscription_end);
    const today = new Date();
    if (currentEndDate < today) {
      currentEndDate = today;
    }

    let newEndDate = new Date(currentEndDate);
    let newPlanId = store.plan_id;

    if (plan_id) {
      const { data: plan } = await supabase
        .from('subscription_plans')
        .select('duration_days')
        .eq('id', plan_id)
        .single();

      if (plan) {
        newEndDate = new Date();
        newEndDate.setDate(newEndDate.getDate() + plan.duration_days);
        newPlanId = plan_id;
      }
    }

    if (additional_days) {
      newEndDate.setDate(newEndDate.getDate() + parseInt(additional_days));
    }

    const { error: updateError } = await supabase
      .from('stores')
      .update({
        subscription_end: newEndDate.toISOString().split('T')[0],
        plan_id: newPlanId,
        is_active: true,
        updated_at: new Date().toISOString()
      })
      .eq('id', id);

    if (updateError) throw updateError;

    await supabase
      .from('audit_logs')
      .insert({
        id: uuidv4(),
        store_id: id,
        user_id: req.user.id,
        action: 'extend_subscription',
        table_name: 'stores',
        record_id: id,
        new_data: {
          additional_days,
          old_end_date: store.subscription_end,
          new_end_date: newEndDate.toISOString().split('T')[0]
        },
        created_at: new Date().toISOString()
      });

    res.json({
      success: true,
      data: {
        store_id: id,
        old_end_date: store.subscription_end,
        new_end_date: newEndDate.toISOString().split('T')[0],
        additional_days
      },
      message: `تم تمديد اشتراك المحل ${store.name} بمقدار ${additional_days} يوم`
    });
  } catch (error) {
    console.error('خطأ في تمديد الاشتراك:', error);
    res.status(500).json({
      success: false,
      error: 'حدث خطأ في الخادم',
      code: 'INTERNAL_ERROR'
    });
  }
});

// POST /api/admin/stores/:id/toggle-status
router.post('/stores/:id/toggle-status', requireSuperAdmin, async (req, res) => {
  try {
    const { id } = req.params;
    const { is_active } = req.body;

    const { data, error } = await supabase
      .from('stores')
      .update({ is_active, updated_at: new Date().toISOString() })
      .eq('id', id)
      .select()
      .single();

    if (error) throw error;

    await logAudit(req, 'UPDATE', 'stores', id, null, { is_active });

    res.json({
      success: true,
      data,
      message: `تم ${is_active ? 'تفعيل' : 'تعطيل'} المحل بنجاح`
    });
  } catch (error) {
    console.error('خطأ في تغيير حالة المحل:', error);
    res.status(500).json({
      success: false,
      error: 'حدث خطأ في الخادم',
      code: 'INTERNAL_ERROR'
    });
  }
});

// GET /api/admin/stores/expiring
router.get('/stores/expiring', async (req, res) => {
  try {
    const today = new Date().toISOString().split('T')[0];
    const nextWeek = new Date();
    nextWeek.setDate(nextWeek.getDate() + 7);
    const nextWeekStr = nextWeek.toISOString().split('T')[0];

    const { data: stores, error } = await supabase
      .from('stores')
      .select('id, name, owner_name, phone, email, subscription_end, is_active')
      .lt('subscription_end', nextWeekStr)
      .gte('subscription_end', today)
      .order('subscription_end', { ascending: true });

    if (error) throw error;

    const expiringStores = stores.map(store => {
      const endDate = new Date(store.subscription_end);
      const todayDate = new Date();
      const daysLeft = Math.ceil((endDate.getTime() - todayDate.getTime()) / (1000 * 60 * 60 * 24));
      return { ...store, days_left: daysLeft };
    });

    res.json({
      success: true,
      data: expiringStores,
      message: 'تم جلب المحلات المنتهية قريباً'
    });
  } catch (error) {
    console.error('خطأ في جلب المحلات المنتهية:', error);
    res.status(500).json({
      success: false,
      error: 'حدث خطأ في الخادم',
      code: 'INTERNAL_ERROR'
    });
  }
});

// POST /api/admin/test-notifications
router.post('/test-notifications', async (req, res) => {
  try {
    const { sendExpiryNotifications } = require('../cron/expiryNotifications');
    await sendExpiryNotifications();
    res.json({ success: true, message: 'تم إرسال التنبيهات بنجاح' });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// GET /api/admin/plans
router.get('/plans', requireSuperAdmin, async (req, res) => {
  try {
    const { data, error } = await supabase
      .from('subscription_plans')
      .select('*')
      .order('duration_days');

    if (error) throw error;

    res.json({ success: true, data: data || [] });
  } catch (error) {
    console.error('خطأ في جلب الخطط:', error);
    res.status(500).json({
      success: false,
      error: 'حدث خطأ في الخادم',
      code: 'INTERNAL_ERROR'
    });
  }
});

// POST /api/admin/plans
router.post('/plans', requireSuperAdmin, async (req, res) => {
  try {
    const { name, duration_days, price_iqd, max_customers, max_employees, features, is_active } = req.body;

    const { data, error } = await supabase
      .from('subscription_plans')
      .insert({
        id: uuidv4(),
        name,
        duration_days,
        price_iqd,
        max_customers: max_customers || 0,
        max_employees: max_employees || 0,
        features: features || [],
        is_active: is_active !== false
      })
      .select()
      .single();

    if (error) throw error;

    await logAudit(req, 'INSERT', 'subscription_plans', data.id, null, data);

    res.json({ success: true, data });
  } catch (error) {
    console.error('خطأ في إنشاء الخطة:', error);
    res.status(500).json({
      success: false,
      error: 'حدث خطأ في الخادم',
      code: 'INTERNAL_ERROR'
    });
  }
});

// PUT /api/admin/plans/:id
router.put('/plans/:id', requireSuperAdmin, async (req, res) => {
  try {
    const { id } = req.params;
    const { name, duration_days, price_iqd, max_customers, max_employees, features, is_active } = req.body;

    const { data, error } = await supabase
      .from('subscription_plans')
      .update({
        name,
        duration_days,
        price_iqd,
        max_customers: max_customers || 0,
        max_employees: max_employees || 0,
        features: features || [],
        is_active: is_active !== undefined ? is_active : true
      })
      .eq('id', id)
      .select()
      .single();

    if (error) {
      console.error('خطأ في تحديث الخطة:', error);
      return res.status(500).json({
        success: false,
        error: 'فشل في تحديث الخطة',
        code: 'INTERNAL_ERROR'
      });
    }

    res.json({ success: true, data, message: 'تم تحديث الخطة بنجاح' });
  } catch (error) {
    console.error('خطأ في تحديث الخطة:', error);
    res.status(500).json({
      success: false,
      error: 'حدث خطأ في الخادم',
      code: 'INTERNAL_ERROR'
    });
  }
});

// DELETE /api/admin/plans/:id
router.delete('/plans/:id', requireSuperAdmin, async (req, res) => {
  try {
    const { id } = req.params;

    const { error } = await supabase
      .from('subscription_plans')
      .delete()
      .eq('id', id);

    if (error) throw error;

    res.json({ success: true, message: 'تم حذف الخطة بنجاح' });
  } catch (error) {
    console.error('خطأ في حذف الخطة:', error);
    res.status(500).json({
      success: false,
      error: 'حدث خطأ في الخادم',
      code: 'INTERNAL_ERROR'
    });
  }
});

// POST /api/admin/stores/:id/users
router.post('/stores/:id/users', requireSuperAdmin, async (req, res) => {
  try {
    const { id } = req.params;
    const { username, full_name, password, role, can_delete, can_edit, can_view_reports } = req.body;

    if (!username || !full_name || !password || !role) {
      return res.status(400).json({
        success: false,
        error: 'جميع الحقول المطلوبة يجب أن توفر',
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
        code: 'USERNAME_EXISTS'
      });
    }

    const hashedPassword = await bcrypt.hash(password, 10);

    const { data: newUser, error } = await supabase
      .from('users')
      .insert({
        store_id: id,
        username,
        full_name,
        password_hash: hashedPassword,
        role: role || 'employee',
        can_delete: can_delete !== false,
        can_edit: can_edit !== false,
        can_view_reports: can_view_reports !== false,
        is_active: true,
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString()
      })
      .select()
      .single();

    if (error) throw error;

    await supabaseAdmin
      .from('audit_logs')
      .insert({
        id: uuidv4(),
        user_id: req.user.id,
        action: 'create_user',
        entity_type: 'user',
        entity_id: newUser.id,
        new_data: { username, full_name, role, store_id: id },
        ip_address: req.ip,
        user_agent: req.get('User-Agent'),
        created_at: new Date().toISOString()
      });

    res.json({ success: true, data: newUser, message: 'تم إضافة الموظف بنجاح' });
  } catch (error) {
    console.error('خطأ في إضافة الموظف:', error);
    res.status(500).json({
      success: false,
      error: 'حدث خطأ في الخادم',
      code: 'INTERNAL_ERROR'
    });
  }
});

// GET /api/admin/audit
router.get('/audit', requireSuperAdmin, async (req, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 50;
    const offset = (page - 1) * limit;
    const action = req.query.action;

    let query = supabase
      .from('audit_logs')
      .select(`
        *,
        users:user_id (username, full_name),
        stores:store_id (name)
      `, { count: 'exact' })
      .order('created_at', { ascending: false });

    if (action) {
      query = query.eq('action', action);
    }

    const { data: logs, error, count } = await query
      .range(offset, offset + limit - 1);

    if (error) throw error;

    const formattedLogs = logs.map(log => ({
      id: log.id,
      user_name: log.users?.full_name || log.users?.username || 'غير معروف',
      store_name: log.stores?.name || 'غير معروف',
      action: log.action,
      table_name: log.table_name,
      record_id: log.record_id,
      created_at: log.created_at,
      ip_address: log.ip_address
    }));

    res.json({
      success: true,
      data: {
        logs: formattedLogs,
        pagination: {
          page,
          limit,
          total: count || 0,
          totalPages: Math.ceil((count || 0) / limit)
        }
      },
      message: 'تم جلب سجل العمليات بنجاح'
    });
  } catch (error) {
    console.error('خطأ في جلب سجل العمليات:', error);
    res.status(500).json({
      success: false,
      error: 'حدث خطأ في الخادم',
      code: 'INTERNAL_ERROR'
    });
  }
});

// GET /api/admin/audit/:id
router.get('/audit/:id', requireSuperAdmin, async (req, res) => {
  try {
    const { id } = req.params;

    const { data: log, error } = await supabase
      .from('audit_logs')
      .select(`
        *,
        users:user_id (username, full_name),
        stores:store_id (name)
      `)
      .eq('id', id)
      .single();

    if (error || !log) {
      return res.status(404).json({
        success: false,
        error: 'السجل غير موجود',
        code: 'NOT_FOUND'
      });
    }

    res.json({
      success: true,
      data: {
        id: log.id,
        user_name: log.users?.full_name || log.users?.username || 'غير معروف',
        store_name: log.stores?.name || 'غير معروف',
        action: log.action,
        table_name: log.table_name,
        record_id: log.record_id,
        created_at: log.created_at,
        ip_address: log.ip_address,
        old_data: log.old_data,
        new_data: log.new_data
      },
      message: 'تم جلب تفاصيل السجل بنجاح'
    });
  } catch (error) {
    console.error('خطأ في جلب تفاصيل السجل:', error);
    res.status(500).json({
      success: false,
      error: 'حدث خطأ في الخادم',
      code: 'INTERNAL_ERROR'
    });
  }
});

// GET /api/admin/super-admins
router.get('/super-admins', requireSuperAdmin, async (req, res) => {
  try {
    const { data, error } = await supabase
      .from('users')
      .select('id, username, full_name, phone, created_at')
      .eq('role', 'super_admin')
      .order('created_at', { ascending: false });

    if (error) throw error;

    res.json({ success: true, data: data || [] });
  } catch (error) {
    console.error('خطأ في جلب السوبر أدمن:', error);
    res.status(500).json({
      success: false,
      error: 'حدث خطأ في الخادم',
      code: 'INTERNAL_ERROR'
    });
  }
});

// POST /api/admin/super-admins
router.post('/super-admins', requireSuperAdmin, async (req, res) => {
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
        code: 'USERNAME_EXISTS'
      });
    }

    const hashedPassword = await bcrypt.hash(password, 10);

    const { data, error } = await supabase
      .from('users')
      .insert({
        username,
        password_hash: hashedPassword,
        full_name,
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

    if (error) throw error;

    await logAudit(req, 'INSERT', 'users', data.id, null, { username, full_name, role: 'super_admin' });

    res.json({ success: true, data, message: 'تم إضافة السوبر أدمن بنجاح' });
  } catch (error) {
    console.error('خطأ في إضافة السوبر أدمن:', error);
    res.status(500).json({
      success: false,
      error: 'حدث خطأ في الخادم',
      code: 'INTERNAL_ERROR'
    });
  }
});

// DELETE /api/admin/super-admins/:id
router.delete('/super-admins/:id', requireSuperAdmin, async (req, res) => {
  try {
    const { id } = req.params;

    const { count } = await supabase
      .from('users')
      .select('*', { count: 'exact', head: true })
      .eq('role', 'super_admin');

    if (count <= 1) {
      return res.status(400).json({
        success: false,
        error: 'لا يمكن حذف آخر سوبر أدمن في النظام',
        code: 'LAST_ADMIN'
      });
    }

    const { data: adminToDelete } = await supabase
      .from('users')
      .select('username, full_name')
      .eq('id', id)
      .single();

    const { error } = await supabase
      .from('users')
      .delete()
      .eq('id', id);

    if (error) throw error;

    await logAudit(req, 'DELETE', 'users', id, adminToDelete, null);

    res.json({ success: true, message: 'تم حذف السوبر أدمن بنجاح' });
  } catch (error) {
    console.error('خطأ في حذف السوبر أدمن:', error);
    res.status(500).json({
      success: false,
      error: 'حدث خطأ في الخادم',
      code: 'INTERNAL_ERROR'
    });
  }
});

// ============================================================
// BACKUP ENDPOINTS - Supabase Storage
// ============================================================

// GET /api/admin/backups - جلب قائمة النسخ الاحتياطية من Supabase Storage
router.get('/backups', requireSuperAdmin, async (req, res) => {
  try {
    const { data: files, error } = await supabaseAdmin
      .storage
      .from('backups')
      .list('', { sortBy: { column: 'created_at', order: 'desc' } });

    if (error) throw error;

    const backups = (files || [])
      .filter(f => f.name.endsWith('.json'))
      .map(f => ({
        name: f.name,
        size: f.metadata?.size || 0,
        created_at: f.created_at
      }));

    res.json({ success: true, data: backups });
  } catch (error) {
    console.error('خطأ في جلب النسخ الاحتياطية:', error);
    res.status(500).json({ success: false, error: 'حدث خطأ في الخادم' });
  }
});

// POST /api/admin/backups - إنشاء نسخة احتياطية ورفعها إلى Supabase Storage
router.post('/backups', requireSuperAdmin, async (req, res) => {
  try {
    const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
    const filename = `backup_manual_${timestamp}.json`;

    console.log('📦 بدء إنشاء نسخة احتياطية...');

    // جلب البيانات من جميع الجداول
    const tables = ['customers', 'products', 'installment_plans', 'payment_schedule', 'payments', 'users', 'stores'];
    const backupData = {};

    for (const table of tables) {
      console.log(`  📥 جلب جدول: ${table}`);
      const { data, error } = await supabase.from(table).select('*');
      if (!error) {
        backupData[table] = data;
        console.log(`     ✅ ${data?.length || 0} سجل`);
      } else {
        console.warn(`     ⚠️ فشل جلب ${table}:`, error.message);
      }
    }

    const fileContent = JSON.stringify(backupData, null, 2);
    console.log(`📄 حجم الملف: ${(fileContent.length / 1024).toFixed(2)} KB`);
    console.log(`📤 رفع إلى Supabase Storage...`);

    // رفع مباشرة إلى Supabase Storage
    const { data, error } = await supabaseAdmin
      .storage
      .from('backups')
      .upload(filename, fileContent, {
        contentType: 'application/json',
        upsert: false
      });

    if (error) {
      console.error('❌ فشل الرفع:', error);
      throw error;
    }

    console.log('✅ تم الرفع بنجاح:', data.path);

    // حذف النسخ القديمة (الاحتفاظ بآخر 30)
    try {
      const { data: allFiles } = await supabaseAdmin
        .storage
        .from('backups')
        .list('', { sortBy: { column: 'created_at', order: 'desc' } });

      const oldFiles = (allFiles || [])
        .filter(f => f.name.endsWith('.json'))
        .slice(30);

      if (oldFiles.length > 0) {
        await supabaseAdmin
          .storage
          .from('backups')
          .remove(oldFiles.map(f => f.name));
        console.log(`🗑️ تم حذف ${oldFiles.length} نسخة قديمة`);
      }
    } catch (cleanupError) {
      console.warn('⚠️ خطأ في تنظيف النسخ القديمة:', cleanupError.message);
    }

    await logAudit(req, 'CREATE_BACKUP', 'system', null, null, { filename });

    res.json({
      success: true,
      data: { filename, size: fileContent.length },
      message: 'تم إنشاء النسخة الاحتياطية بنجاح'
    });

  } catch (error) {
    console.error('❌ خطأ في إنشاء النسخة الاحتياطية:', error);
    res.status(500).json({ success: false, error: error.message || 'حدث خطأ في الخادم' });
  }
});

// GET /api/admin/backups/:filename - تحميل نسخة من Supabase Storage
router.get('/backups/:filename', requireSuperAdmin, async (req, res) => {
  try {
    const { filename } = req.params;

    const { data, error } = await supabaseAdmin
      .storage
      .from('backups')
      .download(filename);

    if (error) throw error;

    const text = await data.text();
    res.setHeader('Content-Disposition', `attachment; filename="${filename}"`);
    res.setHeader('Content-Type', 'application/json');
    res.send(text);
  } catch (error) {
    console.error('خطأ في تحميل النسخة:', error);
    res.status(500).json({ success: false, error: 'حدث خطأ في الخادم' });
  }
});

// DELETE /api/admin/backups/:filename - حذف نسخة من Supabase Storage
router.delete('/backups/:filename', requireSuperAdmin, async (req, res) => {
  try {
    const { filename } = req.params;

    const { error } = await supabaseAdmin
      .storage
      .from('backups')
      .remove([filename]);

    if (error) throw error;

    await logAudit(req, 'DELETE_BACKUP', 'system', null, { filename }, null);

    res.json({ success: true, message: 'تم حذف النسخة بنجاح' });
  } catch (error) {
    console.error('خطأ في حذف النسخة:', error);
    res.status(500).json({ success: false, error: 'حدث خطأ في الخادم' });
  }
});

// POST /api/admin/backups/restore
router.post('/backups/restore', requireSuperAdmin, async (req, res) => {
  try {
    const { filename, store_id } = req.body;
    
    console.log('🚀 بدء استعادة النسخة:', filename);
    console.log('📦 فلتر للمحل:', store_id || 'جميع المحلات');
    
    if (!filename) {
      return res.status(400).json({ success: false, error: 'اسم الملف مطلوب' });
    }
    
    // تحميل الملف من Storage
    const { data: fileData, error: downloadError } = await supabaseAdmin
      .storage
      .from('backups')
      .download(filename);
    
    if (downloadError) {
      console.error('❌ خطأ في تحميل الملف:', downloadError);
      return res.status(404).json({ success: false, error: 'الملف غير موجود' });
    }
    
    const backupData = JSON.parse(await fileData.text());
    console.log('✅ تم تحميل الملف، البيانات:', Object.keys(backupData));
    
    const results = { restored: [], failed: [] };
    
    // ترتيب الحذف (من الأقل اعتماداً إلى الأكثر)
    const deleteOrder = ['payments', 'payment_schedule', 'installment_plans', 'products', 'customers'];
    
    // حذف البيانات الحالية
    for (const table of deleteOrder) {
      if (!backupData[table]) continue;
      
      let query = supabase.from(table).delete();
      if (store_id) {
        query = query.eq('store_id', store_id);
      }
      
      const { error } = await query;
      if (error) {
        console.error(`⚠️ خطأ في حذف جدول ${table}:`, error.message);
      } else {
        console.log(`🗑️ تم حذف بيانات جدول ${table}`);
      }
    }
    
    // ترتيب الإدراج (من الأقل اعتماداً إلى الأكثر)
    const insertOrder = ['customers', 'products', 'installment_plans', 'payment_schedule', 'payments'];
    
    // إدراج البيانات الجديدة
    for (const table of insertOrder) {
      if (!backupData[table]) {
        console.log(`⚠️ جدول ${table} غير موجود في النسخة`);
        continue;
      }
      
      let dataToRestore = backupData[table];
      if (store_id) {
        dataToRestore = dataToRestore.filter(row => row.store_id === store_id);
      }
      
      if (dataToRestore.length === 0) {
        console.log(`⚠️ لا توجد بيانات لجدول ${table} بعد الفلترة`);
        continue;
      }
      
      console.log(`📥 استعادة جدول ${table}: ${dataToRestore.length} سجل`);
      
      // إدراج على دفعات (batch insert)
      const batchSize = 100;
      for (let i = 0; i < dataToRestore.length; i += batchSize) {
        const batch = dataToRestore.slice(i, i + batchSize);
        const { error } = await supabase
          .from(table)
          .insert(batch);
        
        if (error) {
          console.error(`❌ خطأ في استعادة جدول ${table}:`, error.message);
          results.failed.push({ table, error: error.message });
          break;
        }
      }
      
      if (!results.failed.some(f => f.table === table)) {
        results.restored.push({ table, count: dataToRestore.length });
        console.log(`✅ تم استعادة جدول ${table}: ${dataToRestore.length} سجل`);
      }
    }
    
    await logAudit(req, 'RESTORE', 'backup', null, null, { filename, store_id, results });
    
    console.log('🎉 انتهت عملية الاستعادة:', results);
    
    res.json({
      success: true,
      data: results,
      message: `تم استعادة ${results.restored.length} جدول بنجاح` 
    });
  } catch (error) {
    console.error('❌ خطأ في استعادة النسخة:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

// ========== Admin Routes (للسوبر أدمن) ==========

// GET /api/admin/notification-templates
router.get('/notification-templates', requireSuperAdmin, async (req, res) => {
  const { data, error } = await supabase
    .from('notification_templates')
    .select('*')
    .order('type');
  
  if (error) throw error;
  res.json({ success: true, data });
});

// PUT /api/admin/notification-templates/:id
router.put('/notification-templates/:id', requireSuperAdmin, async (req, res) => {
  const { id } = req.params;
  const { body, subject, is_active } = req.body;
  
  const { data, error } = await supabase
    .from('notification_templates')
    .update({ body, subject, is_active, updated_at: new Date().toISOString() })
    .eq('id', id)
    .select()
    .single();
  
  if (error) throw error;
  res.json({ success: true, data });
});

// POST /api/admin/notification-templates/reset
router.post('/notification-templates/reset', requireSuperAdmin, async (req, res) => {
  // إعادة تعيين القوالب إلى الوضع الافتراضي
  const { data, error } = await supabase
    .from('notification_templates')
    .update({ is_active: false })
    .neq('type', 'default');
  
  if (error) throw error;
  
  const { data: defaultTemplates, error: defaultError } = await supabase
    .from('notification_templates')
    .update({ is_active: true })
    .eq('type', 'default');
  
  if (defaultError) throw defaultError;
  
  res.json({ success: true, message: 'تم إعادة تعيين القوالب إلى الوضع الافتراضي' });
});

// GET /api/admin/test-telegram
router.get('/test-telegram', requireSuperAdmin, async (req, res) => {
  const { sendMessage } = require('../services/telegramService');
  await sendMessage(process.env.TELEGRAM_CHAT_ID, '🔄 رسالة تجريبية من نظام مرساة');
  res.json({ success: true, message: 'تم إرسال رسالة تجريبية' });
});

module.exports = router;