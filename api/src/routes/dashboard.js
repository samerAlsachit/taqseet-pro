const express = require('express');
const router = express.Router();
const { authenticateToken } = require('../middleware/auth');
const checkSubscription = require('../middleware/checkSubscription');
const { supabase } = require('../config/supabase');

// GET /api/dashboard/stats
router.get('/stats', [authenticateToken, checkSubscription], async (req, res) => {
  try {
    const storeId = req.user.store_id;

    // إجمالي العملاء
    const { count: totalCustomers, error: customersError } = await supabase
      .from('customers')
      .select('*', { count: 'exact', head: true })
      .eq('store_id', storeId);

    if (customersError) {
      console.error('خطأ في جلب العملاء:', customersError);
    }

    // الأقساط النشطة
    const { count: activeInstallments, error: installmentsError } = await supabase
      .from('installment_plans')
      .select('*', { count: 'exact', head: true })
      .eq('store_id', storeId)
      .eq('status', 'active');

    if (installmentsError) {
      console.error('خطأ في جلب الأقساط:', installmentsError);
    }

    // المستحقة اليوم
    const today = new Date().toISOString().split('T')[0];
    const { count: dueToday, error: dueError } = await supabase
      .from('payment_schedule')
      .select('*', { count: 'exact', head: true })
      .eq('store_id', storeId)
      .eq('due_date', today)
      .eq('status', 'pending');

    if (dueError) {
      console.error('خطأ في جلب المستحقات:', dueError);
    }

    // المتأخرات (تاريخ الاستحقاق أقل من اليوم والحالة pending)
    const { count: overdue, error: overdueError } = await supabase
      .from('payment_schedule')
      .select('*', { count: 'exact', head: true })
      .eq('store_id', storeId)
      .lt('due_date', today)
      .eq('status', 'pending');

    if (overdueError) {
      console.error('خطأ في جلب المتأخرات:', overdueError);
    }

    // تحصيلات اليوم
    const { data: todayPayments, error: paymentsError } = await supabase
      .from('payments')
      .select('amount_paid')
      .eq('store_id', storeId)
      .eq('payment_date', today);

    if (paymentsError) {
      console.error('خطأ في جلب التحصيلات:', paymentsError);
    }

    const todayCollection = todayPayments?.reduce((sum, p) => sum + (p.amount_paid || 0), 0) || 0;

    console.log('Dashboard stats for store:', storeId);
    console.log('Total customers:', totalCustomers);
    console.log('Active installments:', activeInstallments);
    console.log('Due today:', dueToday);
    console.log('Overdue:', overdue);
    console.log('Today collection:', todayCollection);

    res.json({
      success: true,
      data: {
        total_customers: totalCustomers || 0,
        active_installments: activeInstallments || 0,
        due_today: dueToday || 0,
        overdue: overdue || 0,
        today_collection: todayCollection
      },
      message: 'تم جلب الإحصائيات بنجاح'
    });
  } catch (error) {
    console.error('خطأ في جلب إحصائيات dashboard:', error);
    res.status(500).json({
      success: false,
      error: 'حدث خطأ في الخادم',
      code: 'INTERNAL_ERROR'
    });
  }
});

module.exports = router;
