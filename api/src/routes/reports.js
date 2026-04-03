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

// GET /api/reports/profit
router.get('/profit', auth, async (req, res) => {
  try {
    const storeId = req.user.store_id;
    const { period = 'monthly' } = req.query; // daily, monthly, yearly, all
    
    let dateFilter = {};
    const now = new Date();
    
    if (period === 'daily') {
      const today = now.toISOString().split('T')[0];
      dateFilter = { start: today, end: today };
    } else if (period === 'monthly') {
      const firstDay = new Date(now.getFullYear(), now.getMonth(), 1);
      const lastDay = new Date(now.getFullYear(), now.getMonth() + 1, 0);
      dateFilter = { start: firstDay.toISOString().split('T')[0], end: lastDay.toISOString().split('T')[0] };
    } else if (period === 'yearly') {
      const firstDay = new Date(now.getFullYear(), 0, 1);
      const lastDay = new Date(now.getFullYear(), 11, 31);
      dateFilter = { start: firstDay.toISOString().split('T')[0], end: lastDay.toISOString().split('T')[0] };
    }
    
    // 1. أرباح المبيعات بالتقسيط
    let profitQuery = supabase
      .from('installment_plans')
      .select('profit, total_price, currency, created_at')
      .eq('store_id', storeId);
    
    if (dateFilter.start) {
      profitQuery = profitQuery.gte('created_at', `${dateFilter.start}T00:00:00`)
        .lte('created_at', `${dateFilter.end}T23:59:59`);
    }
    
    const { data: installments } = await profitQuery;
    
    const profitIQD = installments?.filter(i => i.currency === 'IQD').reduce((sum, i) => sum + (i.profit || 0), 0) || 0;
    const profitUSD = installments?.filter(i => i.currency === 'USD').reduce((sum, i) => sum + (i.profit || 0), 0) || 0;
    const totalSalesIQD = installments?.filter(i => i.currency === 'IQD').reduce((sum, i) => sum + (i.total_price || 0), 0) || 0;
    const totalSalesUSD = installments?.filter(i => i.currency === 'USD').reduce((sum, i) => sum + (i.total_price || 0), 0) || 0;
    
    // 2. المبيعات النقدية
    let cashQuery = supabase
      .from('cash_sales')
      .select('profit, price, currency, sale_date')
      .eq('store_id', storeId);
    
    if (dateFilter.start) {
      cashQuery = cashQuery.gte('sale_date', dateFilter.start)
        .lte('sale_date', dateFilter.end);
    }
    
    const { data: cashSales } = await cashQuery;
    
    const cashProfitIQD = cashSales?.filter(c => c.currency === 'IQD').reduce((sum, c) => sum + (c.profit || 0), 0) || 0;
    const cashProfitUSD = cashSales?.filter(c => c.currency === 'USD').reduce((sum, c) => sum + (c.profit || 0), 0) || 0;
    const cashSalesIQD = cashSales?.filter(c => c.currency === 'IQD').reduce((sum, c) => sum + (c.price || 0), 0) || 0;
    const cashSalesUSD = cashSales?.filter(c => c.currency === 'USD').reduce((sum, c) => sum + (c.price || 0), 0) || 0;
    
    // 3. ملخص الأرباح
    const profitSummary = {
      period,
      installment_profit: { IQD: profitIQD, USD: profitUSD },
      installment_sales: { IQD: totalSalesIQD, USD: totalSalesUSD },
      cash_profit: { IQD: cashProfitIQD, USD: cashProfitUSD },
      cash_sales: { IQD: cashSalesIQD, USD: cashSalesUSD },
      total_profit: { 
        IQD: profitIQD + cashProfitIQD, 
        USD: profitUSD + cashProfitUSD 
      },
      total_sales: { 
        IQD: totalSalesIQD + cashSalesIQD, 
        USD: totalSalesUSD + cashSalesUSD 
      },
      profit_margin: {
        IQD: (totalSalesIQD + cashSalesIQD) > 0 ? ((profitIQD + cashProfitIQD) / (totalSalesIQD + cashSalesIQD) * 100).toFixed(2) : 0,
        USD: (totalSalesUSD + cashSalesUSD) > 0 ? ((profitUSD + cashProfitUSD) / (totalSalesUSD + cashSalesUSD) * 100).toFixed(2) : 0
      }
    };
    
    res.json({
      success: true,
      data: profitSummary,
      message: 'تم جلب تقرير الأرباح بنجاح'
    });
  } catch (error) {
    console.error('خطأ في جلب تقرير الأرباح:', error);
    res.status(500).json({
      success: false,
      error: 'حدث خطأ في الخادم',
      code: 'INTERNAL_ERROR'
    });
  }
});

// GET /api/reports/profit
router.get('/profit', auth, async (req, res) => {
  try {
    const storeId = req.user.store_id;
    const { period = 'monthly', start_date, end_date } = req.query;
    
    let dateFilter = {};
    const now = new Date();
    
    if (period === 'daily') {
      const today = now.toISOString().split('T')[0];
      dateFilter = { start: today, end: today };
    } else if (period === 'monthly') {
      const firstDay = new Date(now.getFullYear(), now.getMonth(), 1);
      const lastDay = new Date(now.getFullYear(), now.getMonth() + 1, 0);
      dateFilter = { start: firstDay.toISOString().split('T')[0], end: lastDay.toISOString().split('T')[0] };
    } else if (period === 'yearly') {
      const firstDay = new Date(now.getFullYear(), 0, 1);
      const lastDay = new Date(now.getFullYear(), 11, 31);
      dateFilter = { start: firstDay.toISOString().split('T')[0], end: lastDay.toISOString().split('T')[0] };
    } else if (period === 'custom' && start_date && end_date) {
      dateFilter = { start: start_date, end: end_date };
    }
    
    // 1. أرباح المبيعات بالتقسيط
    let profitQuery = supabase
      .from('installment_plans')
      .select('profit, total_price, currency, down_payment, created_at')
      .eq('store_id', storeId);
    
    if (dateFilter.start) {
      profitQuery = profitQuery.gte('created_at', `${dateFilter.start}T00:00:00`)
        .lte('created_at', `${dateFilter.end}T23:59:59`);
    }
    
    const { data: installments } = await profitQuery;
    
    // 2. المبيعات النقدية
    let cashQuery = supabase
      .from('cash_sales')
      .select('profit, price, quantity, currency, sale_date')
      .eq('store_id', storeId);
    
    if (dateFilter.start) {
      cashQuery = cashQuery.gte('sale_date', dateFilter.start)
        .lte('sale_date', dateFilter.end);
    }
    
    const { data: cashSales } = await cashQuery;
    
    // 3. حساب الأرباح حسب العملة
    const installmentProfitIQD = installments?.filter(i => i.currency === 'IQD').reduce((sum, i) => sum + (i.profit || 0), 0) || 0;
    const installmentProfitUSD = installments?.filter(i => i.currency === 'USD').reduce((sum, i) => sum + (i.profit || 0), 0) || 0;
    const installmentSalesIQD = installments?.filter(i => i.currency === 'IQD').reduce((sum, i) => sum + (i.total_price || 0), 0) || 0;
    const installmentSalesUSD = installments?.filter(i => i.currency === 'USD').reduce((sum, i) => sum + (i.total_price || 0), 0) || 0;
    
    const cashProfitIQD = cashSales?.filter(c => c.currency === 'IQD').reduce((sum, c) => sum + (c.profit || 0), 0) || 0;
    const cashProfitUSD = cashSales?.filter(c => c.currency === 'USD').reduce((sum, c) => sum + (c.profit || 0), 0) || 0;
    const cashSalesIQD = cashSales?.filter(c => c.currency === 'IQD').reduce((sum, c) => sum + (c.price * c.quantity || 0), 0) || 0;
    const cashSalesUSD = cashSales?.filter(c => c.currency === 'USD').reduce((sum, c) => sum + (c.price * c.quantity || 0), 0) || 0;
    
    // 4. الملخص النهائي
    const profitSummary = {
      period,
      date_range: dateFilter,
      installment: {
        profit: { IQD: installmentProfitIQD, USD: installmentProfitUSD },
        sales: { IQD: installmentSalesIQD, USD: installmentSalesUSD },
        margin: {
          IQD: installmentSalesIQD > 0 ? (installmentProfitIQD / installmentSalesIQD * 100).toFixed(2) : 0,
          USD: installmentSalesUSD > 0 ? (installmentProfitUSD / installmentSalesUSD * 100).toFixed(2) : 0
        }
      },
      cash: {
        profit: { IQD: cashProfitIQD, USD: cashProfitUSD },
        sales: { IQD: cashSalesIQD, USD: cashSalesUSD },
        margin: {
          IQD: cashSalesIQD > 0 ? (cashProfitIQD / cashSalesIQD * 100).toFixed(2) : 0,
          USD: cashSalesUSD > 0 ? (cashProfitUSD / cashSalesUSD * 100).toFixed(2) : 0
        }
      },
      total: {
        profit: { IQD: installmentProfitIQD + cashProfitIQD, USD: installmentProfitUSD + cashProfitUSD },
        sales: { IQD: installmentSalesIQD + cashSalesIQD, USD: installmentSalesUSD + cashSalesUSD },
        margin: {
          IQD: (installmentSalesIQD + cashSalesIQD) > 0 ? ((installmentProfitIQD + cashProfitIQD) / (installmentSalesIQD + cashSalesIQD) * 100).toFixed(2) : 0,
          USD: (installmentSalesUSD + cashSalesUSD) > 0 ? ((installmentProfitUSD + cashProfitUSD) / (installmentSalesUSD + cashSalesUSD) * 100).toFixed(2) : 0
        }
      }
    };
    
    res.json({
      success: true,
      data: profitSummary,
      message: 'تم جلب تقرير الأرباح بنجاح'
    });
  } catch (error) {
    console.error('خطأ في جلب تقرير الأرباح:', error);
    res.status(500).json({
      success: false,
      error: 'حدث خطأ في الخادم',
      code: 'INTERNAL_ERROR'
    });
  }
});

module.exports = router;
