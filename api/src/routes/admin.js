const express = require('express');
const { supabase, supabaseAdmin } = require('../config/supabase');
const { ERROR_CODES, ERROR_MESSAGES } = require('../config/constants');
const moment = require('moment');
const { v4: uuidv4 } = require('uuid');
const { authenticateToken, requireSuperAdmin } = require('../middleware/auth');

const router = express.Router();

// Apply authentication middleware to all admin routes
router.use(authenticateToken);

/**
 * GET /api/admin/stats
 * جلب إحصائيات عامة للنظام
 */
router.get('/stats', authenticateToken, requireSuperAdmin, async (req, res) => {
  try {
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
        total_revenue: 0 // سنحسبها لاحقاً
      },
      message: 'تم جلب الإحصائيات بنجاح'
    });
  } catch (error) {
    console.error('خطأ في جلب الإحصائيات:', error);
    res.status(500).json({
      success: false,
      error: ERROR_MESSAGES[ERROR_CODES.INTERNAL_ERROR],
      code: ERROR_CODES.INTERNAL_ERROR
    });
  }
});

/**
 * GET /api/admin/stores
 * جلب قائمة المحلات مع الفلاتر
 */
router.get('/stores', authenticateToken, requireSuperAdmin, async (req, res) => {
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

    // بحث
    if (search) {
      query = query.or(`name.ilike.%${search}%,owner_name.ilike.%${search}%,phone.ilike.%${search}%`);
    }

    // فلترة حسب الحالة
    if (status === 'active') {
      query = query.eq('is_active', true);
    } else if (status === 'expired') {
      query = query.lt('subscription_end', new Date().toISOString());
    }

    // جلب البيانات مع Pagination
    const { data: stores, error, count } = await query
      .range(offset, offset + limit - 1)
      .order('created_at', { ascending: false });

    if (error) {
      console.error('خطأ في جلب المحلات:', error);
      throw error;
    }

    // تنسيق البيانات
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
router.get('/activation-codes', authenticateToken, requireSuperAdmin, async (req, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 20;
    const offset = (page - 1) * limit;
    const status = req.query.status || 'all'; // all, used, unused

    // بناء الـ query بدون joins معقدة
    let query = supabase
      .from('activation_codes')
      .select('*', { count: 'exact' });

    // فلترة حسب الحالة
    if (status === 'used') {
      query = query.eq('is_used', true);
    } else if (status === 'unused') {
      query = query.eq('is_used', false);
    }

    const { data: codes, error, count } = await query
      .range(offset, offset + limit - 1)
      .order('created_at', { ascending: false });

    if (error) throw error;

    // جلب بيانات الخطة والمحل لكل كود على حدة
    const formattedCodes = await Promise.all((codes || []).map(async (code) => {
      let planName = null;
      let storeName = null;

      // جلب اسم الخطة
      if (code.plan_id) {
        const { data: plan } = await supabase
          .from('subscription_plans')
          .select('name')
          .eq('id', code.plan_id)
          .single();
        planName = plan?.name;
      }

      // جلب اسم المحل
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
router.get('/subscription-plans', authenticateToken, requireSuperAdmin, async (req, res) => {
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
router.post('/activation-codes', authenticateToken, requireSuperAdmin, async (req, res) => {
  try {
    const { plan_id, quantity = 1, notes } = req.body;

    if (!plan_id) {
      return res.status(400).json({
        success: false,
        error: 'الخطة مطلوبة',
        code: ERROR_CODES.VALIDATION_ERROR
      });
    }

    // جلب تفاصيل الخطة
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
router.post('/stores/:id/extend', authenticateToken, requireSuperAdmin, async (req, res) => {
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

    // جلب المحل الحالي
    const { data: store, error: storeError } = await supabase
      .from('stores')
      .select('subscription_end, plan_id')
      .eq('id', id)
      .single();

    if (storeError || !store) {
      return res.status(404).json({
        success: false,
        error: 'المحل غير موجود',
        code: ERROR_CODES.NOT_FOUND
      });
    }

    let newEndDate = new Date(store.subscription_end);
    let newPlanId = store.plan_id;

    // إذا تم تحديد خطة جديدة
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

    // إضافة أيام إضافية
    if (additional_days) {
      newEndDate.setDate(newEndDate.getDate() + additional_days);
    }

    // تحديث المحل
    const { error: updateError } = await supabase
      .from('stores')
      .update({
        subscription_end: newEndDate.toISOString().split('T')[0],
        plan_id: newPlanId,
        updated_at: new Date().toISOString()
      })
      .eq('id', id);

    if (updateError) throw updateError;

    res.json({
      success: true,
      data: {
        subscription_end: newEndDate.toISOString().split('T')[0],
        plan_id: newPlanId
      },
      message: 'تم تمديد الاشتراك بنجاح'
    });
  } catch (error) {
    console.error('خطأ في تمديد الاشتراك:', error);
    res.status(500).json({
      success: false,
      error: ERROR_MESSAGES[ERROR_CODES.INTERNAL_ERROR],
      code: ERROR_CODES.INTERNAL_ERROR
    });
  }
});

/**
 * POST /api/admin/stores/:id/toggle-status
 * تعطيل/تفعيل محل
 */
router.post('/stores/:id/toggle-status', requireSuperAdmin, async (req, res) => {
  try {
    const { id } = req.params;

    // جلب بيانات المحل
    const { data: store, error: storeError } = await supabase
      .from('stores')
      .select('*')
      .eq('id', id)
      .single();

    if (storeError || !store) {
      return res.status(404).json({
        success: false,
        error: 'المحل غير موجود',
        code: ERROR_CODES.NOT_FOUND
      });
    }

    const newStatus = store.status === 'active' ? 'inactive' : 'active';

    // تحديث حالة المحل
    const { error: updateError } = await supabaseAdmin
      .from('stores')
      .update({
        status: newStatus,
        updated_at: new Date().toISOString()
      })
      .eq('id', id);

    if (updateError) {
      console.error('خطأ في تحديث حالة المحل:', updateError);
      throw updateError;
    }

    // تسجيل العملية
    await supabaseAdmin
      .from('audit_logs')
      .insert({
        id: uuidv4(),
        user_id: req.user.id,
        action: 'toggle_store_status',
        entity_type: 'store',
        entity_id: id,
        old_data: {
          status: store.status
        },
        new_data: {
          status: newStatus
        },
        ip_address: req.ip,
        user_agent: req.get('User-Agent'),
        created_at: new Date().toISOString()
      });

    res.json({
      success: true,
      data: {
        store_id: id,
        old_status: store.status,
        new_status: newStatus
      },
      message: `تم ${newStatus === 'active' ? 'تفعيل' : 'تعطيل'} المحل بنجاح`
    });

  } catch (error) {
    console.error('خطأ في تحديث حالة المحل:', error);
    res.status(500).json({
      success: false,
      error: ERROR_MESSAGES[ERROR_CODES.INTERNAL_ERROR],
      code: ERROR_CODES.INTERNAL_ERROR
    });
  }
});

module.exports = router;
