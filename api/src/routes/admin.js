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
 * POST /api/admin/activation-codes
 * إنشاء كودات تفعيل جديدة
 */
router.post('/activation-codes', requireSuperAdmin, async (req, res) => {
  try {
    const { plan_id, quantity = 1, duration_days, notes } = req.body;

    // التحقق من المدخلات
    if (!plan_id || !duration_days) {
      return res.status(400).json({
        success: false,
        error: 'حقل الخطة ومدة الكود مطلوبان',
        code: ERROR_CODES.VALIDATION_ERROR
      });
    }

    // جلب بيانات الخطة
    const { data: plan, error: planError } = await supabase
      .from('subscription_plans')
      .select('*')
      .eq('id', plan_id)
      .single();

    if (planError || !plan) {
      return res.status(404).json({
        success: false,
        error: 'خطة الاشتراك غير موجودة',
        code: ERROR_CODES.NOT_FOUND
      });
    }

    // إنشاء الكودات
    const codes = [];
    for (let i = 0; i < parseInt(quantity); i++) {
      const code = `TQST-${Date.now()}-${Math.random().toString(36).substr(2, 9).toUpperCase()}`;
      codes.push({
        id: uuidv4(),
        plan_id,
        code,
        duration_days: parseInt(duration_days),
        status: 'active',
        notes: notes || '',
        created_by: req.user.id,
        created_at: new Date().toISOString()
      });
    }

    const { error: insertError } = await supabaseAdmin
      .from('activation_codes')
      .insert(codes);

    if (insertError) {
      console.error('خطأ في إنشاء كودات التفعيل:', insertError);
      throw insertError;
    }

    // تسجيل العملية
    await supabaseAdmin
      .from('audit_logs')
      .insert({
        id: uuidv4(),
        user_id: req.user.id,
        action: 'create_activation_codes',
        entity_type: 'admin',
        new_data: {
          plan_id,
          quantity: codes.length,
          duration_days,
          plan_name: plan.name
        },
        ip_address: req.ip,
        user_agent: req.get('User-Agent'),
        created_at: new Date().toISOString()
      });

    res.status(201).json({
      success: true,
      data: codes.map(c => ({
        id: c.id,
        code: c.code,
        plan_name: plan.name,
        duration_days: c.duration_days,
        status: c.status,
        created_at: c.created_at
      })),
      message: `تم إنشاء ${codes.length} كود تفعيل بنجاح`
    });

  } catch (error) {
    console.error('خطأ في إنشاء كودات التفعيل:', error);
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
router.get('/activation-codes', requireSuperAdmin, async (req, res) => {
  try {
    const {
      page = 1,
      limit = 20,
      is_used = ''
    } = req.query;

    const offset = (parseInt(page) - 1) * parseInt(limit);
    const limitNum = parseInt(limit);

    let query = supabase
      .from('activation_codes')
      .select(`
        *,
        subscription_plans (
          id,
          name as plan_name
        ),
        stores!inner (
          name as store_name,
          owner_name as store_owner
        )
      `, { count: 'exact' })
      .order('created_at', { ascending: false });

    // تطبيق فلتر الاستخدام
    if (is_used !== '') {
      const isUsed = is_used === 'true';
      query = query.eq('is_used', isUsed);
    }

    const { data: codes, error, count } = await query.range(offset, offset + limitNum - 1);

    if (error) {
      console.error('خطأ في جلب كودات التفعيل:', error);
      throw error;
    }

    const totalPages = Math.ceil((count || 0) / limitNum);

    // تسجيل العملية
    await supabaseAdmin
      .from('audit_logs')
      .insert({
        id: uuidv4(),
        user_id: req.user.id,
        action: 'view_activation_codes',
        entity_type: 'admin',
        new_data: {
          page: parseInt(page),
          limit: limitNum,
          is_used,
          results_count: codes?.length || 0
        },
        ip_address: req.ip,
        user_agent: req.get('User-Agent'),
        created_at: new Date().toISOString()
      });

    res.json({
      success: true,
      data: codes || [],
      pagination: {
        page: parseInt(page),
        limit: limitNum,
        total: count || 0,
        totalPages
      }
    });

  } catch (error) {
    console.error('خطأ في جلب كودات التفعيل:', error);
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
router.post('/stores/:id/extend', requireSuperAdmin, async (req, res) => {
  try {
    const { id } = req.params;
    const { additional_days, plan_id } = req.body;

    // التحقق من المدخلات
    if (!additional_days) {
      return res.status(400).json({
        success: false,
        error: 'عدد الأيام الإضافية مطلوب',
        code: ERROR_CODES.VALIDATION_ERROR
      });
    }

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

    // حساب التاريخ الجديد
    const currentEndDate = moment(store.subscription_end);
    const newEndDate = currentEndDate.add(parseInt(additional_days), 'days');

    // تحديث بيانات المحل
    const updateData = {
      subscription_end: newEndDate.toISOString(),
      updated_at: new Date().toISOString()
    };

    if (plan_id) {
      updateData.plan_id = plan_id;
    }

    const { error: updateError } = await supabaseAdmin
      .from('stores')
      .update(updateData)
      .eq('id', id);

    if (updateError) {
      console.error('خطأ في تمديد اشتراك المحل:', updateError);
      throw updateError;
    }

    // تسجيل العملية
    await supabaseAdmin
      .from('audit_logs')
      .insert({
        id: uuidv4(),
        user_id: req.user.id,
        action: 'extend_store_subscription',
        entity_type: 'store',
        entity_id: id,
        old_data: {
          subscription_end: store.subscription_end
        },
        new_data: {
          additional_days: parseInt(additional_days),
          new_subscription_end: newEndDate.toISOString(),
          plan_id
        },
        ip_address: req.ip,
        user_agent: req.get('User-Agent'),
        created_at: new Date().toISOString()
      });

    res.json({
      success: true,
      data: {
        store_id: id,
        previous_end: store.subscription_end,
        new_end: newEndDate.toISOString(),
        additional_days: parseInt(additional_days)
      },
      message: 'تم تمديد اشتراك المحل بنجاح'
    });

  } catch (error) {
    console.error('خطأ في تمديد اشتراك المحل:', error);
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
