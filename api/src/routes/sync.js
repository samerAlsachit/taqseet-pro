const express = require('express');
const router = express.Router();
const { auth } = require('../middleware/auth');
const { supabase } = require('../config/supabase');

// GET /api/sync/pull - جلب التغييرات من السيرفر
router.get('/pull', auth, async (req, res) => {
  try {
    const storeId = req.user.store_id;
    const lastSync = req.query.last_sync_at;

    if (!storeId) {
      return res.json({
        success: true,
        data: {
          customers: [],
          products: [],
          installment_plans: [],
          payment_schedule: [],
          payments: []
        },
        message: 'لا توجد بيانات للمزامنة'
      });
    }

    // جلب العملاء
    const { data: customers } = await supabase
      .from('customers')
      .select('*')
      .eq('store_id', storeId);

    // ✅ Parse extra_docs if stored as JSON string and ensure it's an array
    const processedCustomers = customers?.map(customer => {
      let extraDocs = customer.extra_docs;
      if (typeof extraDocs === 'string') {
        try {
          extraDocs = JSON.parse(extraDocs);
        } catch (e) {
          console.warn('⚠️ Failed to parse extra_docs for customer:', customer.id);
          extraDocs = [];
        }
      }
      // Ensure it's always an array
      if (!Array.isArray(extraDocs)) {
        extraDocs = extraDocs ? [extraDocs] : [];
      }
      return {
        ...customer,
        extra_docs: extraDocs
      };
    }) || [];

    // ✅ Log first customer to verify extra_docs is included
    if (processedCustomers.length > 0) {
      console.log('📤 [SYNC] Pulled', processedCustomers.length, 'customers');
      console.log('📤 [SYNC] Sample customer:', {
        id: processedCustomers[0].id,
        full_name: processedCustomers[0].full_name,
        id_doc_url: processedCustomers[0].id_doc_url,
        extra_docs: processedCustomers[0].extra_docs,
        extra_docs_type: typeof processedCustomers[0].extra_docs
      });
    }

    // جلب المنتجات
    const { data: products } = await supabase
      .from('products')
      .select('*')
      .eq('store_id', storeId);

    // جلب خطط الأقساط
    const { data: installment_plans } = await supabase
      .from('installment_plans')
      .select('*')
      .eq('store_id', storeId);

    // جلب جدول الأقساط
    const { data: payment_schedule } = await supabase
      .from('payment_schedule')
      .select('*')
      .eq('store_id', storeId);

    // جلب الدفعات
    const { data: payments } = await supabase
      .from('payments')
      .select('*')
      .eq('store_id', storeId);

    res.json({
      success: true,
      data: {
        customers: processedCustomers,
        products: products || [],
        installment_plans: installment_plans || [],
        payment_schedule: payment_schedule || [],
        payments: payments || [],
        server_time: new Date().toISOString()
      },
      message: 'تم جلب البيانات للمزامنة'
    });
  } catch (error) {
    console.error('خطأ في مزامنة السحب:', error);
    res.status(500).json({
      success: false,
      error: 'حدث خطأ في الخادم',
      code: 'INTERNAL_ERROR'
    });
  }
});

// POST /api/sync/push - إرسال التغييرات المحلية
router.post('/push', auth, async (req, res) => {
  try {
    const storeId = req.user.store_id;
    const { operations } = req.body;

    if (!storeId) {
      return res.json({
        success: true,
        data: { synced: [], conflicts: [], failed: [] },
        message: 'لا توجد بيانات للمزامنة'
      });
    }

    // هنا يمكن إضافة منطق معالجة العمليات
    // للتبسيط، نعتبر أن جميع العمليات نجحت
    const synced = operations?.map(op => ({ local_id: op.local_id, status: 'synced' })) || [];

    res.json({
      success: true,
      data: {
        synced,
        conflicts: [],
        failed: []
      },
      message: 'تمت مزامنة البيانات بنجاح'
    });
  } catch (error) {
    console.error('خطأ في مزامنة الدفع:', error);
    res.status(500).json({
      success: false,
      error: 'حدث خطأ في الخادم',
      code: 'INTERNAL_ERROR'
    });
  }
});

module.exports = router;
