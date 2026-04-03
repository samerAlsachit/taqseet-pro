const express = require('express');
const router = express.Router();
const { auth, authReadOnly } = require('../middleware/auth');
const { checkSubscription, checkCustomerLimit } = require('../middleware/checkSubscription');
const { logAudit } = require('../middleware/audit');
const { supabase } = require('../config/supabase');
const { v4: uuidv4 } = require('uuid');

// GET /api/customers - قائمة العملاء (قراءة فقط)
router.get('/', authReadOnly, checkSubscription, async (req, res) => {
  try {
    const storeId = req.user.store_id;
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 20;
    const offset = (page - 1) * limit;
    const search = req.query.search || '';

    let query = supabase
      .from('customers')
      .select('*', { count: 'exact' })
      .eq('store_id', storeId);

    if (search) {
      query = query.or(`full_name.ilike.%${search}%,phone.ilike.%${search}%`);
    }

    const { data: customers, error, count } = await query
      .range(offset, offset + limit - 1)
      .order('created_at', { ascending: false });

    if (error) throw error;

    // جلب عدد الأقساط النشطة لكل عميل
    const customersWithCount = await Promise.all((customers || []).map(async (customer) => {
      const { count: activeCount } = await supabase
        .from('installment_plans')
        .select('*', { count: 'exact', head: true })
        .eq('customer_id', customer.id)
        .eq('store_id', storeId)
        .eq('status', 'active');

      return {
        ...customer,
        active_installments_count: activeCount || 0
      };
    }));

    res.json({
      success: true,
      data: {
        customers: customersWithCount,
        pagination: {
          page,
          limit,
          total: count || 0,
          totalPages: Math.ceil((count || 0) / limit)
        }
      },
      message: 'تم جلب العملاء بنجاح'
    });
  } catch (error) {
    console.error('خطأ في جلب العملاء:', error);
    res.status(500).json({
      success: false,
      error: 'حدث خطأ في الخادم',
      code: 'INTERNAL_ERROR'
    });
  }
});

// POST /api/customers - إضافة عميل جديد
router.post('/', auth, checkSubscription, async (req, res) => {
  try {
    const storeId = req.user.store_id;
    const { full_name, phone, phone_alt, address, national_id, notes, local_id } = req.body;

    if (!full_name || !phone) {
      return res.status(400).json({
        success: false,
        error: 'الاسم ورقم الهاتف مطلوبان',
        code: 'VALIDATION_ERROR'
      });
    }

    // التحقق من عدم تكرار رقم الهاتف
    const { data: existing } = await supabase
      .from('customers')
      .select('id')
      .eq('store_id', storeId)
      .eq('phone', phone)
      .single();

    if (existing) {
      return res.status(400).json({
        success: false,
        error: 'رقم الهاتف موجود مسبقاً',
        code: 'DUPLICATE_PHONE'
      });
    }

    // التحقق من حد العملاء
    // if (!await checkCustomerLimit(storeId)) {
    //   return res.status(403).json({
    //     success: false,
    //     error: 'لقد تجاوزت الحد المسموح به من العملاء حسب خطتك',
    //     code: 'LIMIT_EXCEEDED'
    //   });
    // }

    const { data: customer, error } = await supabase
      .from('customers')
      .insert({
        id: uuidv4(),
        store_id: storeId,
        full_name,
        phone,
        phone_alt: phone_alt || '',
        address: address || '',
        national_id: national_id || '',
        notes: notes || '',
        local_id: local_id || null,
        created_by: req.user.id,
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString()
      })
      .select()
      .single();

    if (error) throw error;

    res.status(201).json({
      success: true,
      data: customer,
      message: 'تم إنشاء العميل بنجاح'
    });

    // تسجيل العملية
    await logAudit(req, 'INSERT', 'customers', customer.id, null, customer);
  } catch (error) {
    console.error('خطأ في إنشاء العميل:', error);
    res.status(500).json({
      success: false,
      error: 'حدث خطأ في الخادم',
      code: 'INTERNAL_ERROR'
    });
  }
});

// GET /api/customers/:id - تفاصيل عميل
router.get('/:id', auth, checkSubscription, async (req, res) => {
  try {
    const { id } = req.params;
    const storeId = req.user.store_id;

    const { data: customer, error } = await supabase
      .from('customers')
      .select('*')
      .eq('id', id)
      .eq('store_id', storeId)
      .single();

    if (error || !customer) {
      return res.status(404).json({
        success: false,
        error: 'العميل غير موجود',
        code: 'NOT_FOUND'
      });
    }

    // جلب أقساط العميل
    const { data: installments } = await supabase
      .from('installment_plans')
      .select('id, product_name, total_price, remaining_amount, status, start_date, end_date')
      .eq('customer_id', id)
      .eq('store_id', storeId)
      .order('created_at', { ascending: false });

    res.json({
      success: true,
      data: {
        customer,
        installment_plans: installments || [],
        summary: {
          total_debt: installments?.reduce((sum, p) => sum + (p.remaining_amount || 0), 0) || 0,
          active_installments: installments?.filter(p => p.status === 'active').length || 0,
          overdue_installments: installments?.filter(p => p.status === 'overdue').length || 0
        }
      },
      message: 'تم جلب بيانات العميل بنجاح'
    });
  } catch (error) {
    console.error('خطأ في جلب العميل:', error);
    res.status(500).json({
      success: false,
      error: 'حدث خطأ في الخادم',
      code: 'INTERNAL_ERROR'
    });
  }
});

// PUT /api/customers/:id - تحديث عميل
router.put('/:id', auth, checkSubscription, async (req, res) => {
  try {
    const { id } = req.params;
    const storeId = req.user.store_id;
    const { full_name, phone, phone_alt, address, national_id, notes } = req.body;

    // التحقق من صلاحية التعديل
    if (!req.user.can_edit) {
      return res.status(403).json({
        success: false,
        error: 'غير مصرح، ليس لديك صلاحية التعديل',
        code: 'FORBIDDEN'
      });
    }

    if (!full_name || !phone) {
      return res.status(400).json({
        success: false,
        error: 'الاسم ورقم الهاتف مطلوبان',
        code: 'VALIDATION_ERROR'
      });
    }

    // جلب البيانات القديمة قبل التحديث
    const { data: oldCustomer } = await supabase
      .from('customers')
      .select('*')
      .eq('id', id)
      .eq('store_id', storeId)
      .single();

    const { data: customer, error } = await supabase
      .from('customers')
      .update({
        full_name,
        phone,
        phone_alt: phone_alt || '',
        address: address || '',
        national_id: national_id || '',
        notes: notes || '',
        updated_at: new Date().toISOString()
      })
      .eq('id', id)
      .eq('store_id', storeId)
      .select()
      .single();

    if (error) {
      console.error('خطأ في تحديث العميل:', error);
      return res.status(500).json({
        success: false,
        error: 'فشل في تحديث العميل',
        code: 'INTERNAL_ERROR'
      });
    }

    res.json({
      success: true,
      data: customer,
      message: 'تم تحديث العميل بنجاح'
    });

    // تسجيل العملية
    await logAudit(req, 'UPDATE', 'customers', id, oldCustomer, customer);
  } catch (error) {
    console.error('خطأ في تحديث العميل:', error);
    res.status(500).json({
      success: false,
      error: 'حدث خطأ في الخادم',
      code: 'INTERNAL_ERROR'
    });
  }
});

// DELETE /api/customers/:id - حذف عميل
router.delete('/:id', auth, checkSubscription, async (req, res) => {
  try {
    const { id } = req.params;
    const storeId = req.user.store_id;

    // 1. التحقق من وجود أقساط نشطة
    const { data: activeInstallments } = await supabase
      .from('installment_plans')
      .select('id')
      .eq('customer_id', id)
      .eq('store_id', storeId)
      .in('status', ['active', 'overdue'])
      .limit(1);

    if (activeInstallments && activeInstallments.length > 0) {
      return res.status(400).json({
        success: false,
        error: 'لا يمكن حذف هذا العميل لأنه لديه أقساط غير مكتملة.',
        code: 'HAS_ACTIVE_INSTALLMENTS'
      });
    }

    // 2. جلب جميع أقساط العميل
    const { data: allPlans } = await supabase
      .from('installment_plans')
      .select('id')
      .eq('customer_id', id)
      .eq('store_id', storeId);

    if (allPlans && allPlans.length > 0) {
      const planIds = allPlans.map(p => p.id);
      
      // 1. تحديث payments: تعيين plan_id و schedule_id إلى NULL
      await supabase
        .from('payments')
        .update({ plan_id: null, schedule_id: null })
        .in('plan_id', planIds);
      
      // 2. حذف payment_schedule
      await supabase
        .from('payment_schedule')
        .delete()
        .in('plan_id', planIds);
      
      // 3. حذف installment_plans
      await supabase
        .from('installment_plans')
        .delete()
        .in('id', planIds);
    }

    // جلب بيانات العميل قبل الحذف للتسجيل
    const { data: customerToDelete } = await supabase
      .from('customers')
      .select('*')
      .eq('id', id)
      .single();

    // 3. حذف العميل
    const { error } = await supabase
      .from('customers')
      .delete()
      .eq('id', id)
      .eq('store_id', storeId);

    if (error) throw error;

    // بعد حذف العميل
    await logAudit(req, 'DELETE', 'customers', id, customerToDelete, null);

    res.json({
      success: true,
      message: 'تم حذف العميل بنجاح. تم الاحتفاظ بسجل الدفعات المالية.'
    });
  } catch (error) {
    console.error('خطأ في حذف العميل:', error);
    res.status(500).json({
      success: false,
      error: 'حدث خطأ في الخادم',
      code: 'INTERNAL_ERROR'
    });
  }
});

module.exports = router;
