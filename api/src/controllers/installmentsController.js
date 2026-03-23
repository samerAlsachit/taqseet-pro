const { supabase, supabaseAdmin } = require('../config/supabase');
const { ERROR_CODES, ERROR_MESSAGES } = require('../config/constants');
const { v4: uuidv4 } = require('uuid');
const { calculateInstallments, calculatePlanSummary, updateInstallmentsStatus } = require('../services/installmentCalculator');
const moment = require('moment');

/**
 * حساب جدول الأقساط (للمعاينة فقط)
 */
const calculateInstallmentSchedule = async (req, res) => {
  try {
    const {
      total_price,
      down_payment = 0,
      installment_amount,
      frequency,
      start_date,
      currency = 'IQD'
    } = req.body;

    // التحقق من المدخلات
    if (!total_price || !installment_amount || !frequency || !start_date) {
      return res.status(400).json({
        success: false,
        error: 'جميع الحقول المطلوبة يجب أن توفر',
        code: ERROR_CODES.VALIDATION_ERROR
      });
    }

    // حساب جدول الأقساط
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
      code: ERROR_CODES.VALIDATION_ERROR
    });
  }
};

/**
 * إنشاء خطة قسط جديدة
 */
const createInstallmentPlan = async (req, res) => {
  try {
    const storeId = req.user.store_id;
    const {
      customer_id,
      product_id,
      total_amount,
      down_payment = 0,
      installment_amount,
      frequency,
      start_date,
      currency = 'IQD',
      notes
    } = req.body;

    // التحقق من المدخلات الأساسية
    if (!customer_id || !product_id || !total_amount || !installment_amount || !frequency || !start_date) {
      return res.status(400).json({
        success: false,
        error: 'جميع الحقول المطلوبة يجب أن توفر',
        code: ERROR_CODES.VALIDATION_ERROR
      });
    }

    // التحقق من وجود العميل
    const { data: customer, error: customerError } = await supabase
      .from('customers')
      .select('id, full_name')
      .eq('id', customer_id)
      .eq('store_id', storeId)
      .single();

    if (customerError || !customer) {
      return res.status(404).json({
        success: false,
        error: 'العميل غير موجود',
        code: ERROR_CODES.CUSTOMER_NOT_FOUND
      });
    }

    // التحقق من وجود المنتج والكمية
    const { data: product, error: productError } = await supabase
      .from('products')
      .select('*')
      .eq('id', product_id)
      .eq('store_id', storeId)
      .single();

    if (productError || !product) {
      return res.status(404).json({
        success: false,
        error: 'المنتج غير موجود',
        code: ERROR_CODES.NOT_FOUND
      });
    }

    if (product.quantity <= 0) {
      return res.status(400).json({
        success: false,
        error: 'المنتج غير متوفر في المخزون',
        code: ERROR_CODES.VALIDATION_ERROR
      });
    }

    // حساب جدول الأقساط
    const schedule = calculateInstallments({
      totalPrice: parseFloat(total_amount),
      downPayment: parseFloat(down_payment),
      installmentAmount: parseFloat(installment_amount),
      frequency,
      startDate: start_date,
      currency
    });

    // بدء الـ transaction
    const { data: plan, error: planError } = await supabaseAdmin.rpc('create_installment_plan', {
      p_id: uuidv4(),
      p_store_id: storeId,
      p_customer_id: customer_id,
      p_product_id: product_id,
      p_total_amount: parseFloat(total_amount),
      p_down_payment: parseFloat(down_payment),
      p_currency: currency,
      p_frequency: frequency,
      p_start_date: start_date,
      p_end_date: schedule.endDate,
      p_status: 'active',
      p_notes: notes || '',
      p_installments_count: schedule.installmentsCount,
      p_installment_amount: schedule.installmentAmount,
      p_last_installment_amount: schedule.lastInstallmentAmount,
      p_created_by: req.user.id
    });

    if (planError) {
      console.error('خطأ في إنشاء خطة الأقساط:', planError);
      // في حالة فشل الـ RPC، نستخدم الطريقة العادية
      return await createPlanManually(req, res, schedule, customer, product);
    }

    res.status(201).json({
      success: true,
      data: plan,
      message: 'تم إنشاء خطة الأقساط بنجاح'
    });

  } catch (error) {
    console.error('خطأ في إنشاء خطة الأقساط:', error);
    res.status(500).json({
      success: false,
      error: ERROR_MESSAGES[ERROR_CODES.INTERNAL_ERROR],
      code: ERROR_CODES.INTERNAL_ERROR
    });
  }
};

/**
 * إنشاء خطة الأقسات يدوياً (بدون RPC)
 */
const createPlanManually = async (req, res, schedule, customer, product) => {
  const storeId = req.user.store_id;
  const {
    customer_id,
    product_id,
    total_amount,
    down_payment = 0,
    frequency,
    start_date,
    currency = 'IQD',
    notes
  } = req.body;

  try {
    // إنشاء خطة الأقساط
    const { data: plan, error: planError } = await supabaseAdmin
      .from('installment_plans')
      .insert({
        id: uuidv4(),
        store_id: storeId,
        customer_id,
        product_id,
        total_amount: parseFloat(total_amount),
        down_payment: parseFloat(down_payment),
        currency,
        frequency,
        start_date,
        end_date: schedule.endDate,
        status: 'active',
        notes: notes || '',
        installments_count: schedule.installmentsCount,
        installment_amount: schedule.installmentAmount,
        last_installment_amount: schedule.lastInstallmentAmount,
        created_by: req.user.id,
        created_at: new Date().toISOString()
      })
      .select()
      .single();

    if (planError) {
      console.error('خطأ في إنشاء خطة الأقساط:', planError);
      throw planError;
    }

    // إنشاء جدول الأقساط
    const installmentsData = schedule.schedule.map(item => ({
      id: uuidv4(),
      plan_id: plan.id,
      store_id: storeId,
      customer_id,
      installment_no: item.installment_no,
      due_date: item.due_date,
      amount: item.amount,
      currency: item.currency,
      status: 'pending',
      paid_amount: 0,
      created_at: new Date().toISOString()
    }));

    const { error: installmentsError } = await supabaseAdmin
      .from('payment_schedule')
      .insert(installmentsData);

    if (installmentsError) {
      console.error('خطأ في إنشاء جدول الأقساط:', installmentsError);
      throw installmentsError;
    }

    // إنقاص كمية المنتج
    const { error: productError } = await supabaseAdmin
      .from('products')
      .update({ quantity: product.quantity - 1, updated_at: new Date().toISOString() })
      .eq('id', product_id)
      .eq('store_id', storeId);

    if (productError) {
      console.error('خطأ في تحديث كمية المنتج:', productError);
      throw productError;
    }

    // تسجيل العملية
    await supabaseAdmin
      .from('audit_logs')
      .insert({
        id: uuidv4(),
        user_id: req.user.id,
        store_id: storeId,
        action: 'create_installment_plan',
        entity_type: 'installment_plan',
        entity_id: plan.id,
        new_data: {
          plan,
          customer: customer.full_name,
          product: product.name
        },
        ip_address: req.ip,
        user_agent: req.get('User-Agent'),
        created_at: new Date().toISOString()
      });

    res.status(201).json({
      success: true,
      data: plan,
      message: 'تم إنشاء خطة الأقساط بنجاح'
    });

  } catch (error) {
    console.error('خطأ في إنشاء خطة الأقساط يدوياً:', error);
    res.status(500).json({
      success: false,
      error: ERROR_MESSAGES[ERROR_CODES.INTERNAL_ERROR],
      code: ERROR_CODES.INTERNAL_ERROR
    });
  }
};

/**
 * جلب قائمة خطط الأقساط
 */
const getInstallmentPlans = async (req, res) => {
  try {
    const storeId = req.user.store_id;
    const { status, customer_id, search, page = 1, limit = 20 } = req.query;
    const offset = (page - 1) * limit;
    const limitNum = parseInt(limit);

    let query = supabase
      .from('installment_plans')
      .select(`
        *,
        customers (
          id,
          full_name,
          phone
        ),
        products (
          id,
          name
        )
      `, { count: 'exact' })
      .eq('store_id', storeId)
      .order('created_at', { ascending: false });

    // تطبيق الفلاتر
    if (status) {
      query = query.eq('status', status);
    }
    if (customer_id) {
      query = query.eq('customer_id', customer_id);
    }
    if (search) {
      query = query.or(`customers.full_name.ilike.%${search}%,customers.phone.ilike.%${search}%,products.name.ilike.%${search}%`);
    }

    const { data: plans, error, count } = await query.range(offset, offset + limitNum - 1);

    if (error) {
      console.error('خطأ في جلب خطط الأقساط:', error);
      return res.status(500).json({
        success: false,
        error: ERROR_MESSAGES[ERROR_CODES.INTERNAL_ERROR],
        code: ERROR_CODES.INTERNAL_ERROR
      });
    }

    // حساب الملخص لكل خطة
    const plansWithSummary = await Promise.all(
      (plans || []).map(async (plan) => {
        const { data: installments } = await supabase
          .from('payment_schedule')
          .select('*')
          .eq('plan_id', plan.id);

        const summary = calculatePlanSummary(plan, installments || []);
        return { ...plan, summary };
      })
    );

    const totalPages = Math.ceil(count / limitNum);

    res.json({
      success: true,
      data: {
        plans: plansWithSummary,
        total: count || 0,
        page: parseInt(page),
        totalPages,
        limit: limitNum
      },
      message: 'تم جلب قائمة خطط الأقساط بنجاح'
    });

  } catch (error) {
    console.error('خطأ في جلب خطط الأقساط:', error);
    res.status(500).json({
      success: false,
      error: ERROR_MESSAGES[ERROR_CODES.INTERNAL_ERROR],
      code: ERROR_CODES.INTERNAL_ERROR
    });
  }
};

/**
 * جلب تفاصيل خطة الأقساط
 */
const getInstallmentPlan = async (req, res) => {
  try {
    const storeId = req.user.store_id;
    const { id } = req.params;

    // جلب بيانات الخطة
    const { data: plan, error: planError } = await supabase
      .from('installment_plans')
      .select(`
        *,
        customers (
          id,
          full_name,
          phone,
          address
        ),
        products (
          id,
          name,
          sku
        ),
        users (
          id,
          full_name
        )
      `)
      .eq('id', id)
      .eq('store_id', storeId)
      .single();

    if (planError || !plan) {
      return res.status(404).json({
        success: false,
        error: 'خطة الأقساط غير موجودة',
        code: ERROR_CODES.NOT_FOUND
      });
    }

    // جلب جدول الأقساط
    const { data: installments, error: installmentsError } = await supabase
      .from('payment_schedule')
      .select('*')
      .eq('plan_id', id)
      .order('installment_no', { ascending: true });

    if (installmentsError) {
      console.error('خطأ في جلب جدول الأقساط:', installmentsError);
    }

    // تحديث حالة الأقساط
    const updatedInstallments = updateInstallmentsStatus(installments || []);

    // جلب سجل الدفعات
    const { data: payments, error: paymentsError } = await supabase
      .from('payments')
      .select('*')
      .eq('plan_id', id)
      .order('created_at', { ascending: false });

    if (paymentsError) {
      console.error('خطأ في جلب سجل الدفعات:', paymentsError);
    }

    // حساب الملخص
    const summary = calculatePlanSummary(plan, updatedInstallments);

    res.json({
      success: true,
      data: {
        plan,
        installments: updatedInstallments,
        payments: payments || [],
        summary
      },
      message: 'تم جلب تفاصيل خطة الأقساط بنجاح'
    });

  } catch (error) {
    console.error('خطأ في جلب تفاصيل خطة الأقساط:', error);
    res.status(500).json({
      success: false,
      error: ERROR_MESSAGES[ERROR_CODES.INTERNAL_ERROR],
      code: ERROR_CODES.INTERNAL_ERROR
    });
  }
};

/**
 * جلب الأقساط المستحقة
 */
const getDueInstallments = async (req, res) => {
  try {
    const storeId = req.user.store_id;
    const today = moment().format('YYYY-MM-DD');
    const nextWeek = moment().add(7, 'days').format('YYYY-MM-DD');

    // جلب الأقساط المتأخرة
    const { data: overdue, error: overdueError } = await supabase
      .from('payment_schedule')
      .select(`
        *,
        installment_plans (
          id,
          customers (
            id,
            full_name,
            phone
          ),
          products (
            id,
            name
          )
        )
      `)
      .eq('store_id', storeId)
      .lt('due_date', today)
      .neq('status', 'paid')
      .order('due_date', { ascending: true });

    if (overdueError) {
      console.error('خطأ في جلب الأقساط المتأخرة:', overdueError);
    }

    // جلب أقساط اليوم
    const { data: todayInstallments, error: todayError } = await supabase
      .from('payment_schedule')
      .select(`
        *,
        installment_plans (
          id,
          customers (
            id,
            full_name,
            phone
          ),
          products (
            id,
            name
          )
        )
      `)
      .eq('store_id', storeId)
      .eq('due_date', today)
      .neq('status', 'paid')
      .order('due_date', { ascending: true });

    if (todayError) {
      console.error('خطأ في جلب أقساط اليوم:', todayError);
    }

    // جلب الأقساط القادمة خلال 7 أيام
    const { data: upcoming, error: upcomingError } = await supabase
      .from('payment_schedule')
      .select(`
        *,
        installment_plans (
          id,
          customers (
            id,
            full_name,
            phone
          ),
          products (
            id,
            name
          )
        )
      `)
      .eq('store_id', storeId)
      .gt('due_date', today)
      .lte('due_date', nextWeek)
      .neq('status', 'paid')
      .order('due_date', { ascending: true });

    if (upcomingError) {
      console.error('خطأ في جلب الأقساط القادمة:', upcomingError);
    }

    res.json({
      success: true,
      data: {
        overdue: overdue || [],
        today: todayInstallments || [],
        upcoming: upcoming || []
      },
      message: 'تم جلب الأقساط المستحقة بنجاح'
    });

  } catch (error) {
    console.error('خطأ في جلب الأقساط المستحقة:', error);
    res.status(500).json({
      success: false,
      error: ERROR_MESSAGES[ERROR_CODES.INTERNAL_ERROR],
      code: ERROR_CODES.INTERNAL_ERROR
    });
  }
};

/**
 * إلغاء خطة الأقساط
 */
const cancelInstallmentPlan = async (req, res) => {
  try {
    const storeId = req.user.store_id;
    const { id } = req.params;

    if (!req.user.can_delete) {
      return res.status(403).json({
        success: false,
        error: ERROR_MESSAGES[ERROR_CODES.INSUFFICIENT_PERMISSIONS],
        code: ERROR_CODES.INSUFFICIENT_PERMISSIONS
      });
    }

    // جلب بيانات الخطة
    const { data: plan, error: planError } = await supabase
      .from('installment_plans')
      .select(`
        *,
        products (
          id,
          quantity
        )
      `)
      .eq('id', id)
      .eq('store_id', storeId)
      .single();

    if (planError || !plan) {
      return res.status(404).json({
        success: false,
        error: 'خطة الأقساط غير موجودة',
        code: ERROR_CODES.NOT_FOUND
      });
    }

    if (plan.status === 'cancelled') {
      return res.status(400).json({
        success: false,
        error: 'خطة الأقساط ملغاة بالفعل',
        code: ERROR_CODES.VALIDATION_ERROR
      });
    }

    // التحقق من وجود دفعات
    const { data: payments, error: paymentsError } = await supabase
      .from('payments')
      .select('amount')
      .eq('plan_id', id);

    if (paymentsError) {
      console.error('خطأ في جلب الدفعات:', paymentsError);
    }

    const totalPaid = (payments || []).reduce((sum, payment) => sum + (payment.amount || 0), 0);
    if (totalPaid > 0) {
      return res.status(400).json({
        success: false,
        error: 'لا يمكن إلغاء خطة عليها دفعات مسجلة',
        code: ERROR_CODES.VALIDATION_ERROR
      });
    }

    // بدء الـ transaction
    // 1. إلغاء الخطة
    const { error: cancelError } = await supabaseAdmin
      .from('installment_plans')
      .update({ 
        status: 'cancelled', 
        cancelled_at: new Date().toISOString(),
        cancelled_by: req.user.id
      })
      .eq('id', id)
      .eq('store_id', storeId);

    if (cancelError) {
      console.error('خطأ في إلغاء خطة الأقساط:', cancelError);
      throw cancelError;
    }

    // 2. إلغاء جميع الأقساط
    const { error: installmentsError } = await supabaseAdmin
      .from('payment_schedule')
      .update({ status: 'cancelled' })
      .eq('plan_id', id);

    if (installmentsError) {
      console.error('خطأ في إلغاء الأقساط:', installmentsError);
      throw installmentsError;
    }

    // 3. إرجاع الكمية للمخزون
    const { error: productError } = await supabaseAdmin
      .from('products')
      .update({ 
        quantity: plan.products.quantity + 1, 
        updated_at: new Date().toISOString() 
      })
      .eq('id', plan.product_id)
      .eq('store_id', storeId);

    if (productError) {
      console.error('خطأ في إرجاع الكمية للمخزون:', productError);
      throw productError;
    }

    // تسجيل العملية
    await supabaseAdmin
      .from('audit_logs')
      .insert({
        id: uuidv4(),
        user_id: req.user.id,
        store_id: storeId,
        action: 'cancel_installment_plan',
        entity_type: 'installment_plan',
        entity_id: id,
        old_data: plan,
        new_data: { status: 'cancelled' },
        ip_address: req.ip,
        user_agent: req.get('User-Agent'),
        created_at: new Date().toISOString()
      });

    res.json({
      success: true,
      data: null,
      message: 'تم إلغاء خطة الأقساط بنجاح'
    });

  } catch (error) {
    console.error('خطأ في إلغاء خطة الأقساط:', error);
    res.status(500).json({
      success: false,
      error: ERROR_MESSAGES[ERROR_CODES.INTERNAL_ERROR],
      code: ERROR_CODES.INTERNAL_ERROR
    });
  }
};

module.exports = {
  calculateInstallmentSchedule,
  createInstallmentPlan,
  getInstallmentPlans,
  getInstallmentPlan,
  getDueInstallments,
  cancelInstallmentPlan
};
