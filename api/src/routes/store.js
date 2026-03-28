const express = require('express');
const router = express.Router();
const { auth } = require('../middleware/auth');
const { logAudit } = require('../middleware/audit');
const { supabase } = require('../config/supabase');
const bcrypt = require('bcrypt');

// GET /api/store/settings
router.get('/settings', auth, async (req, res) => {
  try {
    const storeId = req.user.store_id;
    
    if (!storeId) {
      return res.status(400).json({
        success: false,
        error: 'لا يوجد محل مرتبط بهذا المستخدم',
        code: 'NO_STORE'
      });
    }

    const { data: store, error } = await supabase
      .from('stores')
      .select('id, name, owner_name, phone, address, city, logo_url, receipt_header, receipt_footer, default_currency, subscription_start, subscription_end, is_active')
      .eq('id', storeId)
      .single();

    if (error || !store) {
      return res.status(404).json({
        success: false,
        error: 'المحل غير موجود',
        code: 'NOT_FOUND'
      });
    }

    res.json({
      success: true,
      data: store,
      message: 'تم جلب إعدادات المحل بنجاح'
    });
  } catch (error) {
    console.error('خطأ في جلب إعدادات المحل:', error);
    res.status(500).json({
      success: false,
      error: 'حدث خطأ في الخادم',
      code: 'INTERNAL_ERROR'
    });
  }
});

// PUT /api/store/settings
router.put('/settings', auth, async (req, res) => {
  try {
    const storeId = req.user.store_id;
    const { name, owner_name, phone, address, city, receipt_header, receipt_footer, default_currency } = req.body;

    if (!storeId) {
      return res.status(400).json({
        success: false,
        error: 'لا يوجد محل مرتبط بهذا المستخدم',
        code: 'NO_STORE'
      });
    }

    // جلب البيانات القديمة قبل التحديث
    const { data: oldStore } = await supabase
      .from('stores')
      .select('*')
      .eq('id', storeId)
      .single();

    const { data: store, error } = await supabase
      .from('stores')
      .update({
        name: name || undefined,
        owner_name: owner_name || undefined,
        phone: phone || undefined,
        address: address || '',
        city: city || '',
        receipt_header: receipt_header || '',
        receipt_footer: receipt_footer || '',
        default_currency: req.body.default_currency || 'IQD',
        updated_at: new Date().toISOString()
      })
      .eq('id', storeId)
      .select()
      .single();

    if (error) {
      console.error('خطأ في تحديث إعدادات المحل:', error);
      return res.status(500).json({
        success: false,
        error: 'فشل في تحديث الإعدادات',
        code: 'INTERNAL_ERROR'
      });
    }

    res.json({
      success: true,
      data: store,
      message: 'تم تحديث إعدادات المحل بنجاح'
    });

    // تسجيل العملية
    await logAudit(req, 'UPDATE', 'stores', storeId, oldStore, store);
  } catch (error) {
    console.error('خطأ في تحديث إعدادات المحل:', error);
    res.status(500).json({
      success: false,
      error: 'حدث خطأ في الخادم',
      code: 'INTERNAL_ERROR'
    });
  }
});

// GET /api/store/employees
router.get('/employees', auth, async (req, res) => {
  const storeId = req.user.store_id;
  
  // جلب الحد الأقصى من الخطة
  const { data: store } = await supabase
    .from('stores')
    .select('plan_id')
    .eq('id', storeId)
    .single();
  
  let maxEmployees = 2; // افتراضي
  if (store.plan_id) {
    const { data: plan } = await supabase
      .from('subscription_plans')
      .select('max_employees')
      .eq('id', store.plan_id)
      .single();
    maxEmployees = plan?.max_employees || 2;
  }
  
  // جلب الموظفين (غير المالك)
  const { data: employees, error } = await supabase
    .from('users')
    .select('id, username, full_name, phone, role, can_delete, can_edit, can_view_reports, is_active, created_at')
    .eq('store_id', storeId)
    .neq('role', 'store_owner');
  
  if (error) throw error;
  
  res.json({
    success: true,
    data: {
      employees: employees || [],
      current: employees?.length || 0,
      max: maxEmployees
    }
  });
});

// POST /api/store/employees
router.post('/employees', auth, async (req, res) => {
  const storeId = req.user.store_id;
  const { username, full_name, phone, password, role, can_delete, can_edit, can_view_reports } = req.body;
  
  // التحقق من الحد الأقصى
  const { data: store } = await supabase
    .from('stores')
    .select('plan_id')
    .eq('id', storeId)
    .single();
  
  let maxEmployees = 2;
  if (store.plan_id) {
    const { data: plan } = await supabase
      .from('subscription_plans')
      .select('max_employees')
      .eq('id', store.plan_id)
      .single();
    maxEmployees = plan?.max_employees || 2;
  }
  
  const { count } = await supabase
    .from('users')
    .select('*', { count: 'exact', head: true })
    .eq('store_id', storeId)
    .neq('role', 'store_owner');
  
  if (count >= maxEmployees) {
    return res.status(403).json({
      success: false,
      error: 'لقد وصلت إلى الحد الأقصى للموظفين حسب خطتك',
      code: 'LIMIT_EXCEEDED'
    });
  }
  
  const hashedPassword = await bcrypt.hash(password, 10);
  
  const { data, error } = await supabase
    .from('users')
    .insert({
      store_id: storeId,
      username,
      full_name,
      phone: phone || '',
      password_hash: hashedPassword,
      role: role || 'store_employee',
      can_delete: can_delete || false,
      can_edit: can_edit !== false,
      can_view_reports: can_view_reports || false,
      is_active: true
    })
    .select()
    .single();
  
  if (error) throw error;
  
  res.json({ success: true, data, message: 'تم إضافة الموظف بنجاح' });
});

// PUT /api/store/employees/:id
router.put('/employees/:id', auth, async (req, res) => {
  const { id } = req.params;
  const storeId = req.user.store_id;
  const { can_delete, can_edit, can_view_reports } = req.body;
  
  const { data, error } = await supabase
    .from('users')
    .update({
      can_delete,
      can_edit,
      can_view_reports,
      updated_at: new Date().toISOString()
    })
    .eq('id', id)
    .eq('store_id', storeId)
    .select()
    .single();
  
  if (error) throw error;
  
  res.json({ success: true, data, message: 'تم تحديث الصلاحيات' });
});

// DELETE /api/store/employees/:id
router.delete('/employees/:id', auth, async (req, res) => {
  const { id } = req.params;
  const storeId = req.user.store_id;
  
  const { error } = await supabase
    .from('users')
    .delete()
    .eq('id', id)
    .eq('store_id', storeId);
  
  if (error) throw error;
  
  res.json({ success: true, message: 'تم حذف الموظف بنجاح' });
});

// GET /api/store/audit
router.get('/audit', auth, async (req, res) => {
  try {
    const storeId = req.user.store_id;
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 50;
    const offset = (page - 1) * limit;
    const action = req.query.action;

    let query = supabase
      .from('audit_logs')
      .select(`
        *,
        users:user_id (username, full_name)
      `, { count: 'exact' })
      .eq('store_id', storeId)
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

// GET /api/store/audit/:id
router.get('/audit/:id', auth, async (req, res) => {
  try {
    const { id } = req.params;
    const storeId = req.user.store_id;

    const { data: log, error } = await supabase
      .from('audit_logs')
      .select(`
        *,
        users:user_id (username, full_name)
      `)
      .eq('id', id)
      .eq('store_id', storeId)
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

module.exports = router;
