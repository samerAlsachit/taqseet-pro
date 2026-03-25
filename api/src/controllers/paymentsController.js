const { supabase, supabaseAdmin } = require('../config/supabase');
const { ERROR_CODES, ERROR_MESSAGES } = require('../config/constants');
const { v4: uuidv4 } = require('uuid');
const { calculatePlanSummary, updateInstallmentsStatus } = require('../services/installmentCalculator');
const { generateReceiptHTML, prepareReceiptData } = require('../services/receiptGenerator');
const moment = require('moment');

/**
 * توليد رقم وصل تسلسلي
 */
const generateReceiptNumber = async (storeId) => {
  const today = moment().format('YYYYMMDD');
  const storeIdShort = storeId.substring(0, 8);
  
  // جلب آخر رقم وصل لهذا المحل في نفس اليوم
  const { data: lastReceipt, error } = await supabase
    .from('payments')
    .select('receipt_number')
    .eq('store_id', storeId)
    .like('receipt_number', `RCP-${storeIdShort}-${today}-%`)
    .order('receipt_number', { ascending: false })
    .limit(1)
    .single();

  let sequence = 1;
  if (!error && lastReceipt) {
    const lastSequence = parseInt(lastReceipt.receipt_number.split('-')[2]) || 0;
    sequence = lastSequence + 1;
  }

  return `RCP-${storeIdShort}-${today}-${sequence.toString().padStart(4, '0')}`;
};

/**
 * إنشاء دفعة جديدة
 */
const createPayment = async (req, res) => {
  try {
    const storeId = req.user.store_id;
    const {
      plan_id,
      schedule_id,
      amount_paid,
      payment_date = new Date().toISOString().split('T')[0],
      notes
    } = req.body;

    // التحقق من المدخلات
    if (!plan_id || !schedule_id || !amount_paid) {
      return res.status(400).json({
        success: false,
        error: 'جميع الحقول المطلوبة يجب أن توفر',
        code: ERROR_CODES.VALIDATION_ERROR
      });
    }

    // 1. جلب خطة القسط
    const { data: plan, error: planError } = await supabase
      .from('installment_plans')
      .select('*')
      .eq('id', plan_id)
      .eq('store_id', storeId)
      .single();

    if (planError || !plan) {
      return res.status(404).json({
        success: false,
        error: 'خطة القسط غير موجودة',
        code: ERROR_CODES.NOT_FOUND
      });
    }

    // 2. جلب تفاصيل القسط من جدول المدفوعات
    const { data: schedule, error: scheduleError } = await supabase
      .from('payment_schedule')
      .select('*')
      .eq('id', schedule_id)
      .eq('plan_id', plan_id)
      .single();

    if (scheduleError || !schedule) {
      return res.status(404).json({
        success: false,
        error: 'القسط غير موجود',
        code: ERROR_CODES.NOT_FOUND
      });
    }

    // 3. التحقق من أن القسط لم يُدفع بعد
    if (schedule.status === 'paid') {
      return res.status(400).json({
        success: false,
        error: 'هذا القسط تم دفعه مسبقاً',
        code: ERROR_CODES.VALIDATION_ERROR
      });
    }

    // 4. التحقق من أن المبلغ المدفوع يساوي قيمة القسط (أو أقل في حالة الدفع الجزئي)
    if (amount_paid > schedule.amount) {
      return res.status(400).json({
        success: false,
        error: 'المبلغ المدفوع أكبر من قيمة القسط',
        code: ERROR_CODES.VALIDATION_ERROR
      });
    }

    // 5. إنشاء رقم وصل
    const receiptNumber = `RCP-${storeId.slice(0, 8)}-${Date.now()}`;

    // 6. إدراج الدفعة
    const { data: payment, error: paymentError } = await supabase
      .from('payments')
      .insert({
        id: uuidv4(),
        schedule_id: schedule_id,
        plan_id: plan_id,
        store_id: storeId,
        received_by: req.user.id,
        amount_paid: amount_paid,
        payment_date: payment_date,
        is_early: payment_date < schedule.due_date,
        receipt_number: receiptNumber,
        notes: notes,
        created_at: new Date().toISOString()
      })
      .select()
      .single();

    if (paymentError) {
      console.error('خطأ في إنشاء الدفعة:', paymentError);
      return res.status(500).json({
        success: false,
        error: 'فشل في تسجيل الدفعة',
        code: ERROR_CODES.INTERNAL_ERROR
      });
    }

    // 7. تحديث حالة القسط في payment_schedule
    const { error: updateScheduleError } = await supabase
      .from('payment_schedule')
      .update({ 
        status: 'paid'
      })
      .eq('id', schedule_id);

    if (updateScheduleError) {
      console.error('خطأ في تحديث القسط:', updateScheduleError);
    }

    // 8. حساب المبلغ المتبقي الجديد
    const newTotalPaid = (plan.total_paid || 0) + amount_paid;
    const newRemainingAmount = plan.total_price - plan.down_payment - newTotalPaid;

    // 9. تحديث خطة الأقساط
    const { error: updatePlanError } = await supabase
      .from('installment_plans')
      .update({
        total_paid: newTotalPaid,
        remaining_amount: newRemainingAmount,
        updated_at: new Date().toISOString()
      })
      .eq('id', plan_id);

    if (updatePlanError) {
      console.error('خطأ في تحديث خطة الأقساط:', updatePlanError);
    }

    // 10. التحقق إذا اكتملت الخطة
    if (newRemainingAmount <= 0) {
      await supabase
        .from('installment_plans')
        .update({ status: 'completed' })
        .eq('id', plan_id);
    }

    res.json({
      success: true,
      data: {
        payment,
        receipt_number: receiptNumber,
        remaining_amount: newRemainingAmount,
        receipt_data: {
          receipt_number: receiptNumber,
          payment_date: payment_date,
          customer_name: plan.customer_name || 'غير محدد',
          store_name: req.user.store_name || 'تقسيط برو',
          amount_paid: amount_paid,
          remaining_amount: newRemainingAmount
        }
      },
      message: 'تم تسجيل الدفعة بنجاح'
    });

  } catch (error) {
    console.error('خطأ في إنشاء الدفعة:', error);
    res.status(500).json({
      success: false,
      error: ERROR_MESSAGES[ERROR_CODES.INTERNAL_ERROR],
      code: ERROR_CODES.INTERNAL_ERROR
    });
  }
};

/**
 * جلب بيانات الوصل للطباعة
 */
const getReceipt = async (req, res) => {
  try {
    const storeId = req.user.store_id;
    const { receipt_number } = req.params;

    // جلب بيانات الدفعة
    const { data: payment, error: paymentError } = await supabase
      .from('payments')
      .select(`
        *,
        installment_plans (
          id,
          total_amount,
          down_payment,
          installments_count,
          frequency,
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
      .eq('receipt_number', receipt_number)
      .eq('store_id', storeId)
      .single();

    if (paymentError || !payment) {
      return res.status(404).json({
        success: false,
        error: 'الوصل غير موجود',
        code: ERROR_CODES.NOT_FOUND
      });
    }

    // جلب بيانات المحل
    const { data: store, error: storeError } = await supabase
      .from('stores')
      .select('*')
      .eq('id', storeId)
      .single();

    if (storeError || !store) {
      return res.status(404).json({
        success: false,
        error: 'المحل غير موجود',
        code: ERROR_CODES.STORE_NOT_FOUND
      });
    }

    const plan = payment.installment_plans;
    const remainingAmount = plan.total_amount - (plan.total_paid || 0);
    const installmentsRemaining = plan.installments_count - (plan.paid_installments || 0);

    const receiptData = {
      receipt_number: payment.receipt_number,
      payment_date: payment.payment_date,
      customer: {
        name: plan.customers.full_name,
        phone: plan.customers.phone
      },
      store: {
        name: store.name,
        phone: store.phone,
        address: store.address,
        logo_url: store.logo_url,
        receipt_header: store.receipt_header,
        receipt_footer: store.receipt_footer
      },
      product_name: plan.products.name,
      amount_paid: payment.amount_paid,
      remaining_amount: remainingAmount,
      installments_remaining: installmentsRemaining,
      plan_summary: {
        total: plan.total_amount,
        paid: plan.total_paid || 0,
        remaining: remainingAmount
      }
    };

    res.json({
      success: true,
      data: receiptData,
      message: 'تم جلب بيانات الوصل بنجاح'
    });

  } catch (error) {
    console.error('خطأ في جلب بيانات الوصل:', error);
    res.status(500).json({
      success: false,
      error: ERROR_MESSAGES[ERROR_CODES.INTERNAL_ERROR],
      code: ERROR_CODES.INTERNAL_ERROR
    });
  }
};

/**
 * طباعة الوصل (HTML)
 */
const printReceipt = async (req, res) => {
  try {
    const { receipt_number } = req.params;
    const { type = 'a4' } = req.query; // a4, thermal58, thermal80

    // جلب بيانات الوصل
    const receiptResponse = await getReceipt({ 
      ...req, 
      params: { receipt_number } 
    }, {
      json: (data) => data
    });

    if (!receiptResponse.success) {
      return res.status(receiptResponse.status || 500).json(receiptResponse);
    }

    const receiptData = receiptResponse.data;

    // توليد HTML للطباعة
    const receiptHTML = await generateReceiptHTML(receiptData, type);

    res.setHeader('Content-Type', 'text/html; charset=utf-8');
    res.send(receiptHTML);

  } catch (error) {
    console.error('خطأ في طباعة الوصل:', error);
    res.status(500).json({
      success: false,
      error: ERROR_MESSAGES[ERROR_CODES.INTERNAL_ERROR],
      code: ERROR_CODES.INTERNAL_ERROR
    });
  }
};

/**
 * جلب كشف حساب العميل
 */
const getStatement = async (req, res) => {
  try {
    const storeId = req.user.store_id;
    const { plan_id } = req.params;

    // جلب بيانات خطة الأقساط
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
          name
        )
      `)
      .eq('id', plan_id)
      .eq('store_id', storeId)
      .single();

    if (planError || !plan) {
      return res.status(404).json({
        success: false,
        error: 'خطة الأقساط غير موجودة',
        code: ERROR_CODES.NOT_FOUND
      });
    }

    // جلب بيانات المحل
    const { data: store, error: storeError } = await supabase
      .from('stores')
      .select('*')
      .eq('id', storeId)
      .single();

    if (storeError || !store) {
      return res.status(404).json({
        success: false,
        error: 'المحل غير موجود',
        code: ERROR_CODES.STORE_NOT_FOUND
      });
    }

    // جلب سجل الدفعات
    const { data: payments, error: paymentsError } = await supabase
      .from('payments')
      .select('*')
      .eq('plan_id', plan_id)
      .eq('store_id', storeId)
      .order('payment_date', { ascending: true });

    if (paymentsError) {
      console.error('خطأ في جلب الدفعات:', paymentsError);
    }

    // جلب جدول الأقساط
    const { data: schedule, error: scheduleError } = await supabase
      .from('payment_schedule')
      .select('*')
      .eq('plan_id', plan_id)
      .eq('store_id', storeId)
      .order('installment_no', { ascending: true });

    if (scheduleError) {
      console.error('خطأ في جلب جدول الأقساط:', scheduleError);
    }

    // تحديث حالة الأقساط
    const updatedSchedule = updateInstallmentsStatus(schedule || []);

    // حساب الملخص
    const totalPaid = (payments || []).reduce((sum, payment) => sum + (payment.amount_paid || 0), 0);
    const remainingAmount = plan.total_amount - totalPaid;
    
    // البحث عن تاريخ الاستحقاق القادم
    let nextDueDate = null;
    const pendingInstallments = updatedSchedule.filter(i => i.status === 'pending' || i.status === 'overdue');
    if (pendingInstallments.length > 0) {
      nextDueDate = pendingInstallments[0].due_date;
    }

    const statementData = {
      customer: plan.customers,
      store: store,
      product_name: plan.products.name,
      plan: {
        total: plan.total_amount,
        down_payment: plan.down_payment,
        financed: plan.total_amount - (plan.down_payment || 0),
        installments_count: plan.installments_count,
        frequency: plan.frequency
      },
      payments: payments || [],
      schedule: updatedSchedule,
      summary: {
        total_paid: totalPaid,
        remaining: remainingAmount,
        next_due_date: nextDueDate
      }
    };

    res.json({
      success: true,
      data: statementData,
      message: 'تم جلب كشف الحساب بنجاح'
    });

  } catch (error) {
    console.error('خطأ في جلب كشف الحساب:', error);
    res.status(500).json({
      success: false,
      error: ERROR_MESSAGES[ERROR_CODES.INTERNAL_ERROR],
      code: ERROR_CODES.INTERNAL_ERROR
    });
  }
};

module.exports = {
  createPayment,
  getReceipt,
  printReceipt,
  getStatement
};
