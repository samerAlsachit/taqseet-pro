const express = require('express');
const router = express.Router();
const { auth } = require('../middleware/auth');
const { checkSubscription } = require('../middleware/checkSubscription');
const { supabase } = require('../config/supabase');

// GET /api/dashboard/stats
router.get('/stats', [auth, checkSubscription], async (req, res) => {
  try {
    const storeId = req.user.store_id;
    const today = new Date().toISOString().split('T')[0];

    // إجمالي العملاء
    const { count: totalCustomers } = await supabase
      .from('customers')
      .select('*', { count: 'exact', head: true })
      .eq('store_id', storeId);

    // الأقساط النشطة
    const { count: activeInstallments } = await supabase
      .from('installment_plans')
      .select('*', { count: 'exact', head: true })
      .eq('store_id', storeId)
      .eq('status', 'active');

    // المستحقة اليوم والمتأخرات حسب العملة
    const { data: dueToday } = await supabase
      .from('payment_schedule')
      .select(`
        amount,
        currency,
        installment_plans!plan_id (currency)
      `)
      .eq('store_id', storeId)
      .eq('due_date', today)
      .eq('status', 'pending');

    const { data: overdue } = await supabase
      .from('payment_schedule')
      .select(`
        amount,
        currency,
        installment_plans!plan_id (currency)
      `)
      .eq('store_id', storeId)
      .lt('due_date', today)
      .eq('status', 'pending');

    // تحصيلات اليوم حسب العملة
    const { data: todayPayments } = await supabase
      .from('payments')
      .select('amount_paid, currency')
      .eq('store_id', storeId)
      .eq('payment_date', today);

    // تجميع حسب العملة
    const dueTodayIQD = dueToday?.filter(p => p.installment_plans?.currency === 'IQD').reduce((sum, p) => sum + (p.amount || 0), 0) || 0;
    const dueTodayUSD = dueToday?.filter(p => p.installment_plans?.currency === 'USD').reduce((sum, p) => sum + (p.amount || 0), 0) || 0;
    
    const overdueIQD = overdue?.filter(p => p.installment_plans?.currency === 'IQD').reduce((sum, p) => sum + (p.amount || 0), 0) || 0;
    const overdueUSD = overdue?.filter(p => p.installment_plans?.currency === 'USD').reduce((sum, p) => sum + (p.amount || 0), 0) || 0;
    
    const todayCollectionIQD = todayPayments?.filter(p => p.currency === 'IQD').reduce((sum, p) => sum + (p.amount_paid || 0), 0) || 0;
    const todayCollectionUSD = todayPayments?.filter(p => p.currency === 'USD').reduce((sum, p) => sum + (p.amount_paid || 0), 0) || 0;

    res.json({
      success: true,
      data: {
        total_customers: totalCustomers || 0,
        active_installments: activeInstallments || 0,
        due_today: {
          IQD: dueTodayIQD,
          USD: dueTodayUSD
        },
        overdue: {
          IQD: overdueIQD,
          USD: overdueUSD
        },
        today_collection: {
          IQD: todayCollectionIQD,
          USD: todayCollectionUSD
        }
      },
      message: 'تم جلب الإحصائيات بنجاح'
    });
  } catch (error) {
    console.error('خطأ في جلب الإحصائيات:', error);
    res.status(500).json({
      success: false,
      error: 'حدث خطأ في الخادم',
      code: 'INTERNAL_ERROR'
    });
  }
});

module.exports = router;
