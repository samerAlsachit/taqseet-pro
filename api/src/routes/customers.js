const express = require('express');
const router = express.Router();
const { auth, authReadOnly } = require('../middleware/auth');
const { checkSubscription, checkCustomerLimit } = require('../middleware/checkSubscription');
const { logAudit } = require('../middleware/audit');
const { supabase } = require('../config/supabase');
const { v4: uuidv4 } = require('uuid');

// ✅ استيراد دوال الـ Controller
const customersController = require('../controllers/customersController');

// GET /api/customers - قائمة العملاء (قراءة فقط)
router.get('/', authReadOnly, checkSubscription, customersController.getCustomers);

// POST /api/customers - إضافة عميل جديد
// ✅ يدعم الآن: id, full_name, phone, national_id, address, id_doc_url, extra_docs
router.post('/', auth, checkSubscription, customersController.createCustomer);

// GET /api/customers/:id - تفاصيل عميل
router.get('/:id', auth, checkSubscription, customersController.getCustomer);

// PUT /api/customers/:id - تحديث عميل
// ✅ يدعم الآن: id_doc_url, extra_docs, national_id
router.put('/:id', auth, checkSubscription, customersController.updateCustomer);

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
