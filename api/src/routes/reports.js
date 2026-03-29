const express = require('express');
const router = express.Router();
const { auth } = require('../middleware/auth');
const { checkSubscription } = require('../middleware/checkSubscription');
const { supabase } = require('../config/supabase');

// GET /api/reports/summary
router.get('/summary', [auth, checkSubscription], async (req, res) => {
  try {
    const storeId = req.user.store_id;
    const today = new Date().toISOString().split('T')[0];
    const firstDayOfMonth = new Date();
    firstDayOfMonth.setDate(1);
    firstDayOfMonth.setHours(0, 0, 0, 0);
    const monthStart = firstDayOfMonth.toISOString().split('T')[0];

    // التحصيلات اليومية حسب العملة
    const { data: dailyPayments } = await supabase
      .from('payments')
      .select('amount_paid, currency')
      .eq('store_id', storeId)
      .eq('payment_date', today);

    const dailyCollectionIQD = dailyPayments?.filter(p => p.currency === 'IQD').reduce((sum, p) => sum + (p.amount_paid || 0), 0) || 0;
    const dailyCollectionUSD = dailyPayments?.filter(p => p.currency === 'USD').reduce((sum, p) => sum + (p.amount_paid || 0), 0) || 0;
    const dailyPaidCount = dailyPayments?.length || 0;

    // الأقساط الجديدة اليوم
    const { count: dailyNewInstallments } = await supabase
      .from('installment_plans')
      .select('*', { count: 'exact', head: true })
      .eq('store_id', storeId)
      .gte('created_at', `${today}T00:00:00`);

    // التحصيلات الشهرية حسب العملة
    const { data: monthlyPayments } = await supabase
      .from('payments')
      .select('amount_paid, currency')
      .eq('store_id', storeId)
      .gte('payment_date', monthStart);

    const monthlyCollectionIQD = monthlyPayments?.filter(p => p.currency === 'IQD').reduce((sum, p) => sum + (p.amount_paid || 0), 0) || 0;
    const monthlyCollectionUSD = monthlyPayments?.filter(p => p.currency === 'USD').reduce((sum, p) => sum + (p.amount_paid || 0), 0) || 0;
    const monthlyPaidCount = monthlyPayments?.length || 0;

    const { count: monthlyNewInstallments } = await supabase
      .from('installment_plans')
      .select('*', { count: 'exact', head: true })
      .eq('store_id', storeId)
      .gte('created_at', `${monthStart}T00:00:00`);

    // الإجمالي الكلي حسب العملة
    const { data: allPayments } = await supabase
      .from('payments')
      .select('amount_paid, currency')
      .eq('store_id', storeId);

    const totalCollectionIQD = allPayments?.filter(p => p.currency === 'IQD').reduce((sum, p) => sum + (p.amount_paid || 0), 0) || 0;
    const totalCollectionUSD = allPayments?.filter(p => p.currency === 'USD').reduce((sum, p) => sum + (p.amount_paid || 0), 0) || 0;
    const allPaymentsCount = allPayments?.length || 0;

    // عدد الدفعات الكلي (من payments)
    const { count: totalPaidCount } = await supabase
      .from('payments')
      .select('*', { count: 'exact', head: true })
      .eq('store_id', storeId);

    // عدد الأقساط الجديدة الكلي
    const { count: totalNewInstallmentsCount } = await supabase
      .from('installment_plans')
      .select('*', { count: 'exact', head: true })
      .eq('store_id', storeId);

    // المتبقي حسب العملة
    const { data: totalRemaining } = await supabase
      .from('installment_plans')
      .select('remaining_amount, currency')
      .eq('store_id', storeId)
      .eq('status', 'active');

    const totalRemainingIQD = totalRemaining?.filter(p => p.currency === 'IQD').reduce((sum, p) => sum + (p.remaining_amount || 0), 0) || 0;
    const totalRemainingUSD = totalRemaining?.filter(p => p.currency === 'USD').reduce((sum, p) => sum + (p.remaining_amount || 0), 0) || 0;

    const { count: activeInstallments } = await supabase
      .from('installment_plans')
      .select('*', { count: 'exact', head: true })
      .eq('store_id', storeId)
      .eq('status', 'active');

    const { count: totalCustomers } = await supabase
      .from('customers')
      .select('*', { count: 'exact', head: true })
      .eq('store_id', storeId);

    const { count: totalInstallmentsCount } = await supabase
      .from('installment_plans')
      .select('*', { count: 'exact', head: true })
      .eq('store_id', storeId);

    // عدد الدفعات الكلي (من payments)
    const { count: allPaidCount } = await supabase
      .from('payments')
      .select('*', { count: 'exact', head: true })
      .eq('store_id', storeId);

    // عدد الأقساط الجديدة الكلي
    const { count: totalNewInstallments } = await supabase
      .from('installment_plans')
      .select('*', { count: 'exact', head: true })
      .eq('store_id', storeId);

    res.json({
      success: true,
      data: {
        daily: {
          total_collection: {
            IQD: dailyCollectionIQD,
            USD: dailyCollectionUSD
          },
          paid_count: dailyPaidCount,
          new_installments: dailyNewInstallments || 0
        },
        monthly: {
          total_collection: {
            IQD: monthlyCollectionIQD,
            USD: monthlyCollectionUSD
          },
          paid_count: monthlyPaidCount,
          new_installments: monthlyNewInstallments || 0
        },
        total: {
          total_collection: {
            IQD: totalCollectionIQD,
            USD: totalCollectionUSD
          },
          total_remaining: {
            IQD: totalRemainingIQD,
            USD: totalRemainingUSD
          },
          active_installments: activeInstallments || 0,
          total_customers: totalCustomers || 0,
          total_installments: totalInstallmentsCount || 0,
          paid_count: totalPaidCount || 0,
          new_installments: totalNewInstallmentsCount || 0
        }
      },
      message: 'تم جلب التقارير بنجاح'
    });
  } catch (error) {
    console.error('خطأ في جلب التقارير:', error);
    res.status(500).json({
      success: false,
      error: 'حدث خطأ في الخادم',
      code: 'INTERNAL_ERROR'
    });
  }
});

module.exports = router;
