const express = require('express');
const router = express.Router();
const { auth } = require('../middleware/auth');
const { checkSubscription } = require('../middleware/checkSubscription');
const { supabase } = require('../config/supabase');
const { v4: uuidv4 } = require('uuid');

// دالة حساب الأقساط
const calculateInstallments = (params) => {
  const { totalPrice, downPayment, installmentAmount, frequency, startDate, currency } = params;
  
  const financedAmount = totalPrice - downPayment;
  const installmentsCount = Math.ceil(financedAmount / installmentAmount);
  const lastInstallmentAmount = financedAmount - (installmentAmount * (installmentsCount - 1));
  
  const schedule = [];
  let currentDate = new Date(startDate);
  
  for (let i = 1; i <= installmentsCount; i++) {
    let dueDate = new Date(currentDate);
    if (frequency === 'monthly') {
      dueDate.setMonth(currentDate.getMonth() + (i - 1));
    } else if (frequency === 'weekly') {
      dueDate.setDate(currentDate.getDate() + (i - 1) * 7);
    } else {
      dueDate.setDate(currentDate.getDate() + (i - 1));
    }
    
    schedule.push({
      installment_no: i,
      due_date: dueDate.toISOString().split('T')[0],
      amount: i === installmentsCount ? lastInstallmentAmount : installmentAmount,
      currency
    });
  }
  
  const endDate = schedule[schedule.length - 1].due_date;
  
  return {
    financedAmount,
    installmentsCount,
    installmentAmount,
    lastInstallmentAmount,
    startDate,
    endDate,
    frequency,
    currency,
    schedule
  };
};

// GET /api/installments
router.get('/', auth, checkSubscription, async (req, res) => {
  try {
    const storeId = req.user.store_id;
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 20;
    const offset = (page - 1) * limit;
    const search = req.query.search || '';
    const status = req.query.status;

    let query = supabase
      .from('installment_plans')
      .select(`
        *,
        customers:customer_id (full_name, phone)
      `, { count: 'exact' })
      .eq('store_id', storeId);

    if (status && status !== 'all') {
      query = query.eq('status', status);
    }

    if (search) {
      query = query.or(`product_name.ilike.%${search}%,customers.full_name.ilike.%${search}%`);
    }

    const { data: plans, error, count } = await query
      .range(offset, offset + limit - 1)
      .order('created_at', { ascending: false });

    if (error) throw error;

    // جلب عدد الأقساط المدفوعة لكل خطة
    const plansWithDetails = await Promise.all((plans || []).map(async (plan) => {
      const { data: schedule } = await supabase
        .from('payment_schedule')
        .select('status')
        .eq('plan_id', plan.id);

      const paidCount = schedule?.filter(s => s.status === 'paid').length || 0;
      const totalCount = schedule?.length || plan.installments_count;

      return {
        id: plan.id,
        customer_name: plan.customers?.full_name || 'غير محدد',
        customer_phone: plan.customers?.phone || '',
        product_name: plan.product_name,
        total_price: plan.total_price,
        remaining_amount: plan.remaining_amount,
        status: plan.status,
        start_date: plan.start_date,
        end_date: plan.end_date,
        paid_count: paidCount,
        total_count: totalCount
      };
    }));

    res.json({
      success: true,
      data: {
        installments: plansWithDetails,
        pagination: {
          page,
          limit,
          total: count || 0,
          totalPages: Math.ceil((count || 0) / limit)
        }
      },
      message: 'تم جلب الأقساط بنجاح'
    });
  } catch (error) {
    console.error('خطأ في جلب الأقساط:', error);
    res.status(500).json({
      success: false,
      error: 'حدث خطأ في الخادم',
      code: 'INTERNAL_ERROR'
    });
  }
});

// POST /api/installments/calculate
router.post('/calculate', auth, checkSubscription, async (req, res) => {
  try {
    const { total_price, down_payment = 0, installment_amount, frequency, start_date, currency = 'IQD' } = req.body;

    if (!total_price || !installment_amount || !frequency || !start_date) {
      return res.status(400).json({
        success: false,
        error: 'جميع الحقول المطلوبة يجب أن توفر',
        code: 'VALIDATION_ERROR'
      });
    }

    const schedule = calculateInstallments({
      totalPrice: parseFloat(total_price),
      downPayment: parseFloat(down_payment),
      installmentAmount: parseFloat(installment_amount),
      frequency,
      startDate: start_date,
      currency
    });

    res.json({
      success: true,
      data: schedule,
      message: 'تم حساب جدول الأقساط بنجاح'
    });
  } catch (error) {
    console.error('خطأ في حساب جدول الأقساط:', error);
    res.status(400).json({
      success: false,
      error: error.message || 'فشل في حساب جدول الأقساط',
      code: 'VALIDATION_ERROR'
    });
  }
});

// POST /api/installments
router.post('/', auth, checkSubscription, async (req, res) => {
  try {
    const storeId = req.user.store_id;
    const { customer_id, product_id, total_price, down_payment = 0, installment_amount, frequency, start_date, currency = 'IQD', notes } = req.body;

    if (!customer_id || !product_id || !total_price || !installment_amount || !frequency || !start_date) {
      return res.status(400).json({
        success: false,
        error: 'جميع الحقول المطلوبة يجب أن توفر',
        code: 'VALIDATION_ERROR'
      });
    }

    // التحقق من العميل
    const { data: customer } = await supabase
      .from('customers')
      .select('id, full_name')
      .eq('id', customer_id)
      .eq('store_id', storeId)
      .single();

    if (!customer) {
      return res.status(404).json({
        success: false,
        error: 'العميل غير موجود',
        code: 'NOT_FOUND'
      });
    }

    // التحقق من المنتج
    const { data: product } = await supabase
      .from('products')
      .select('*')
      .eq('id', product_id)
      .eq('store_id', storeId)
      .single();

    if (!product || product.quantity <= 0) {
      return res.status(400).json({
        success: false,
        error: 'المنتج غير متوفر',
        code: 'PRODUCT_NOT_AVAILABLE'
      });
    }

    const schedule = calculateInstallments({
      totalPrice: parseFloat(total_price),
      downPayment: parseFloat(down_payment),
      installmentAmount: parseFloat(installment_amount),
      frequency,
      startDate: start_date,
      currency
    });

    const planId = uuidv4();
    const financedAmount = total_price - down_payment;

    // إنشاء خطة القسط
    const { data: plan, error: planError } = await supabase
      .from('installment_plans')
      .insert({
        id: planId,
        store_id: storeId,
        customer_id: customer_id,
        product_id: product_id,
        created_by: req.user.id,
        product_name: product.name,
        total_price: total_price,
        down_payment: down_payment,
        financed_amount: financedAmount,
        remaining_amount: financedAmount,
        total_paid: 0,
        currency: currency,
        frequency: frequency,
        start_date: start_date,
        end_date: schedule.endDate,
        status: 'active',
        installments_count: schedule.installmentsCount,
        installment_amount: schedule.installmentAmount,
        last_installment_amount: schedule.lastInstallmentAmount,
        notes: notes || '',
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString()
      })
      .select()
      .single();

    if (planError) {
      console.error('خطأ في إنشاء الخطة:', planError);
      throw planError;
    }

    // إنشاء جدول الأقساط
    const scheduleInserts = schedule.schedule.map(item => ({
      id: uuidv4(),
      plan_id: planId,
      store_id: storeId,
      installment_no: item.installment_no,
      due_date: item.due_date,
      amount: item.amount,
      status: 'pending',
      created_at: new Date().toISOString()
    }));

    await supabase.from('payment_schedule').insert(scheduleInserts);

    // تنقيص المخزون
    await supabase
      .from('products')
      .update({ quantity: product.quantity - 1 })
      .eq('id', product_id);

    res.status(201).json({
      success: true,
      data: plan,
      message: 'تم إنشاء خطة الأقساط بنجاح'
    });
  } catch (error) {
    console.error('خطأ في إنشاء القسط:', error);
    res.status(500).json({
      success: false,
      error: 'حدث خطأ في الخادم',
      code: 'INTERNAL_ERROR'
    });
  }
});

// GET /api/installments/:id
router.get('/:id', auth, checkSubscription, async (req, res) => {
  try {
    const { id } = req.params;
    const storeId = req.user.store_id;

    const { data: plan, error: planError } = await supabase
      .from('installment_plans')
      .select(`
        *,
        customers:customer_id (full_name, phone),
        products:product_id (name)
      `)
      .eq('id', id)
      .eq('store_id', storeId)
      .single();

    if (planError || !plan) {
      return res.status(404).json({
        success: false,
        error: 'خطة القسط غير موجودة',
        code: 'NOT_FOUND'
      });
    }

    const { data: schedule } = await supabase
      .from('payment_schedule')
      .select('*')
      .eq('plan_id', id)
      .order('installment_no');

    const { data: payments } = await supabase
      .from('payments')
      .select('*')
      .eq('plan_id', id)
      .order('payment_date');

    res.json({
      success: true,
      data: {
        plan: {
          ...plan,
          customer_name: plan.customers?.full_name,
          customer_phone: plan.customers?.phone,
          product_name: plan.products?.name
        },
        installments: schedule || [],
        payments: payments || []
      },
      message: 'تم جلب تفاصيل القسط بنجاح'
    });
  } catch (error) {
    console.error('خطأ في جلب تفاصيل القسط:', error);
    res.status(500).json({
      success: false,
      error: 'حدث خطأ في الخادم',
      code: 'INTERNAL_ERROR'
    });
  }
});

module.exports = router;
