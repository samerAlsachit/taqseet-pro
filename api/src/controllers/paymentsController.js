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
      payment_date,
      notes,
      local_id
    } = req.body;

    // التحقق من المدخلات الأساسية
    if (!plan_id || !amount_paid || !payment_date) {
      return res.status(400).json({
        success: false,
        error: 'خطة الأقساط والمبلغ المدفوع وتاريخ الدفع مطلوبون',
        code: ERROR_CODES.VALIDATION_ERROR
      });
    }

    // جلب بيانات خطة الأقساط
    const { data: plan, error: planError } = await supabase
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
      `)
      .eq('id', plan_id)
      .eq('store_id', storeId)
      .eq('status', 'active')
      .single();

    if (planError || !plan) {
      return res.status(404).json({
        success: false,
        error: 'خطة الأقساط غير موجودة أو غير نشطة',
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

    let installmentToUpdate = null;
    let isEarlyPayment = false;

    if (schedule_id) {
      // دفعة لقسط محدد
      const { data: installment, error: installmentError } = await supabase
        .from('payment_schedule')
        .select('*')
        .eq('id', schedule_id)
        .eq('plan_id', plan_id)
        .eq('store_id', storeId)
        .neq('status', 'paid')
        .single();

      if (installmentError || !installment) {
        return res.status(404).json({
          success: false,
          error: 'القسط المحدد غير موجود أو تم دفعه',
          code: ERROR_CODES.NOT_FOUND
        });
      }

      installmentToUpdate = installment;
    } else {
      // دفعة مبكرة
      isEarlyPayment = true;
    }

    // توليد رقم الوصل
    const receiptNumber = await generateReceiptNumber(storeId);

    // حساب المبلغ المتبقي
    const currentTotalPaid = plan.total_paid || 0;
    const newTotalPaid = currentTotalPaid + parseFloat(amount_paid);
    const remainingAmount = plan.total_amount - newTotalPaid;

    // بدء الـ transaction
    // 1. إنشاء سجل الدفع
    const { data: payment, error: paymentError } = await supabaseAdmin
      .from('payments')
      .insert({
        id: uuidv4(),
        store_id: storeId,
        plan_id,
        schedule_id: schedule_id || null,
        customer_id: plan.customer_id,
        receipt_number: receiptNumber,
        amount_paid: parseFloat(amount_paid),
        payment_date,
        is_early_payment: isEarlyPayment,
        notes: notes || '',
        local_id: local_id || null,
        created_by: req.user.id,
        created_at: new Date().toISOString()
      })
      .select()
      .single();

    if (paymentError) {
      console.error('خطأ في إنشاء الدفعة:', paymentError);
      throw paymentError;
    }

    // 2. تحديث القسط إذا كان محدداً
    if (installmentToUpdate) {
      const installmentAmount = installmentToUpdate.amount;
      const newPaidAmount = (installmentToUpdate.paid_amount || 0) + parseFloat(amount_paid);
      
      const { error: updateInstallmentError } = await supabaseAdmin
        .from('payment_schedule')
        .update({
          paid_amount: newPaidAmount,
          status: newPaidAmount >= installmentAmount ? 'paid' : 'pending',
          paid_at: newPaidAmount >= installmentAmount ? new Date().toISOString() : null,
          updated_at: new Date().toISOString()
        })
        .eq('id', installmentToUpdate.id);

      if (updateInstallmentError) {
        console.error('خطأ في تحديث القسط:', updateInstallmentError);
        throw updateInstallmentError;
      }
    }

    // 3. تحديث خطة الأقساط
    const planUpdateData = {
      total_paid: newTotalPaid,
      remaining_amount: remainingAmount,
      updated_at: new Date().toISOString()
    };

    if (remainingAmount <= 0) {
      planUpdateData.status = 'completed';
      planUpdateData.completed_at = new Date().toISOString();
    }

    const { error: updatePlanError } = await supabaseAdmin
      .from('installment_plans')
      .update(planUpdateData)
      .eq('id', plan_id)
      .eq('store_id', storeId);

    if (updatePlanError) {
      console.error('خطأ في تحديث خطة الأقساط:', updatePlanError);
      throw updatePlanError;
    }

    // 4. تحديث حالة الأقساط المتأخرة
    if (!isEarlyPayment) {
      const { data: allInstallments } = await supabase
        .from('payment_schedule')
        .select('*')
        .eq('plan_id', plan_id)
        .eq('store_id', storeId)
        .neq('status', 'paid');

      if (allInstallments) {
        const updatedInstallments = updateInstallmentsStatus(allInstallments);
        
        for (const installment of updatedInstallments) {
          if (installment.status !== allInstallments.find(i => i.id === installment.id)?.status) {
            await supabaseAdmin
              .from('payment_schedule')
              .update({ status: installment.status, updated_at: new Date().toISOString() })
              .eq('id', installment.id);
          }
        }
      }
    }

    // 5. تسجيل العملية في audit_logs
    await supabaseAdmin
      .from('audit_logs')
      .insert({
        id: uuidv4(),
        user_id: req.user.id,
        store_id: storeId,
        action: 'create_payment',
        entity_type: 'payment',
        entity_id: payment.id,
        new_data: {
          receipt_number: receiptNumber,
          amount_paid: parseFloat(amount_paid),
          customer_name: plan.customers.full_name,
          product_name: plan.products.name
        },
        ip_address: req.ip,
        user_agent: req.get('User-Agent'),
        created_at: new Date().toISOString()
      });

    // 6. توليد بيانات الوصل
    const receiptData = prepareReceiptData(payment, plan, store);

    res.status(201).json({
      success: true,
      data: {
        payment,
        receipt_number: receiptNumber,
        remaining_amount: remainingAmount,
        receipt_data: receiptData
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
