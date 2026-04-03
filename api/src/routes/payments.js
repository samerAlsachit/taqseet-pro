const express = require('express');
const router = express.Router();
const { auth } = require('../middleware/auth');
const { checkSubscription } = require('../middleware/checkSubscription');
const { logAudit } = require('../middleware/audit');
const { supabase } = require('../config/supabase');
const { v4: uuidv4 } = require('uuid');
const { getNotificationText } = require('../services/templateService');
const { sendTelegramMessage } = require('../services/telegramService');

// POST /api/payments
router.post('/', auth, checkSubscription, async (req, res) => {
  try {
    const storeId = req.user.store_id;
    const { plan_id, schedule_id, amount_paid, payment_date, notes } = req.body;

    if (!plan_id || !schedule_id || !amount_paid) {
      return res.status(400).json({
        success: false,
        error: 'جميع الحقول المطلوبة يجب أن توفر',
        code: 'VALIDATION_ERROR'
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
        code: 'NOT_FOUND'
      });
    }

    if (plan.status !== 'active') {
      return res.status(400).json({
        success: false,
        error: 'لا يمكن تسديد دفعة لخطة قسط غير نشطة',
        code: 'INVALID_STATUS'
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
        code: 'NOT_FOUND'
      });
    }

    // 3. التحقق من أن القسط لم يُدفع بعد
    if (schedule.status === 'paid') {
      return res.status(400).json({
        success: false,
        error: 'هذا القسط تم دفعه مسبقاً',
        code: 'ALREADY_PAID'
      });
    }

    // 4. التحقق من المبلغ
    if (amount_paid > schedule.amount) {
      return res.status(400).json({
        success: false,
        error: 'المبلغ المدفوع أكبر من قيمة القسط',
        code: 'INVALID_AMOUNT'
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
        payment_date: payment_date || new Date().toISOString().split('T')[0],
        is_early: payment_date < schedule.due_date,
        receipt_number: receiptNumber,
        notes: notes || '',
        created_at: new Date().toISOString()
      })
      .select()
      .single();

    if (paymentError) {
      console.error('خطأ في إنشاء الدفعة:', paymentError);
      return res.status(500).json({
        success: false,
        error: 'فشل في تسجيل الدفعة',
        code: 'INTERNAL_ERROR'
      });
    }

    // 7. تحديث حالة القسط في payment_schedule
    await supabase
      .from('payment_schedule')
      .update({ status: 'paid' })
      .eq('id', schedule_id);

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

    // 10. إرسال إشعار وصل الدفع باستخدام القالب
    try {
      // جلب بيانات العميل
      const { data: customerData } = await supabase
        .from('customers')
        .select('full_name, telegram_chat_id')
        .eq('id', plan.customer_id)
        .single();

      if (customerData) {
        const message = await getNotificationText('payment_receipt', {
          customer_name: customerData.full_name,
          amount: amount_paid,
          currency: plan.currency,
          receipt_no: receiptNumber,
          remaining: newRemainingAmount
        });

        // إرسال إلى تلجرام إذا كان الزبون لديه chat_id
        if (customerData.telegram_chat_id) {
          await sendTelegramMessage(customerData.telegram_chat_id, message);
          console.log(`📱 تم إرسال إشعار وصل الدفع إلى ${customerData.full_name}`);
        }
      }
    } catch (notificationError) {
      console.error('خطأ في إرسال إشعار الوصل:', notificationError);
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
          payment_date: payment.payment_date,
          amount_paid: amount_paid,
          remaining_amount: newRemainingAmount
        }
      },
      message: 'تم تسجيل الدفعة بنجاح'
    });

    // تسجيل العملية
    await logAudit(req, 'INSERT', 'payments', payment.id, null, payment);
  } catch (error) {
    console.error('خطأ في إنشاء الدفعة:', error);
    res.status(500).json({
      success: false,
      error: 'حدث خطأ في الخادم',
      code: 'INTERNAL_ERROR'
    });
  }
});

// GET /api/payments/receipt/:receipt_number
router.get('/receipt/:receipt_number', auth, checkSubscription, async (req, res) => {
  try {
    const { receipt_number } = req.params;
    const storeId = req.user.store_id;

    const { data: payment, error } = await supabase
      .from('payments')
      .select(`
        *,
        installment_plans!plan_id (
          id,
          total_price,
          remaining_amount,
          customer_id,
          product_name,
          customers:customer_id (full_name, phone)
        )
      `)
      .eq('receipt_number', receipt_number)
      .eq('store_id', storeId)
      .single();

    if (error || !payment) {
      return res.status(404).json({
        success: false,
        error: 'الوصل غير موجود',
        code: 'NOT_FOUND'
      });
    }

    const { data: store } = await supabase
      .from('stores')
      .select('name, phone, address, logo_url, receipt_header, receipt_footer')
      .eq('id', storeId)
      .single();

    res.json({
      success: true,
      data: {
        receipt: payment,
        store,
        customer: payment.installment_plans?.customers
      },
      message: 'تم جلب الوصل بنجاح'
    });
  } catch (error) {
    console.error('خطأ في جلب الوصل:', error);
    res.status(500).json({
      success: false,
      error: 'حدث خطأ في الخادم',
      code: 'INTERNAL_ERROR'
    });
  }
});

// POST /api/payments/full-settlement
router.post('/full-settlement', auth, checkSubscription, async (req, res) => {
  try {
    const storeId = req.user.store_id;
    const { plan_id, amount_paid, payment_date, notes, discount_type, discount_value } = req.body;

    if (!plan_id || !amount_paid) {
      return res.status(400).json({
        success: false,
        error: 'معرف الخطة والمبلغ المدفوع مطلوبان',
        code: 'VALIDATION_ERROR'
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
        code: 'NOT_FOUND'
      });
    }

    if (plan.status !== 'active') {
      return res.status(400).json({
        success: false,
        error: 'هذه الخطة غير نشطة',
        code: 'INVALID_STATUS'
      });
    }

    // 2. جلب جميع الأقساط المتبقية
    const { data: pendingSchedules, error: scheduleError } = await supabase
      .from('payment_schedule')
      .select('*')
      .eq('plan_id', plan_id)
      .eq('status', 'pending')
      .order('installment_no', { ascending: true });

    if (scheduleError || !pendingSchedules || pendingSchedules.length === 0) {
      return res.status(400).json({
        success: false,
        error: 'لا توجد أقساط متبقية للدفع',
        code: 'NO_PENDING'
      });
    }

    const totalPendingAmount = pendingSchedules.reduce((sum, s) => sum + s.amount, 0);

// حساب المبلغ المطلوب بعد التخفيض
let requiredAmount = totalPendingAmount;
let discountAmount = 0;

if (discount_type && discount_value > 0) {
  if (discount_type === 'percentage') {
    discountAmount = totalPendingAmount * discount_value / 100;
    requiredAmount = totalPendingAmount - discountAmount;
  } else if (discount_type === 'fixed') {
    discountAmount = discount_value;
    requiredAmount = totalPendingAmount - discount_value;
  }
}

// التأكد من أن requiredAmount لا يقل عن 0
requiredAmount = Math.max(0, requiredAmount);

// التحقق من أن المبلغ المدفوع كافٍ
if (amount_paid < requiredAmount) {
  return res.status(400).json({
    success: false,
    error: `المبلغ المدفوع غير كافٍ. المطلوب بعد التخفيض: ${requiredAmount.toLocaleString()} ${plan.currency}`,
    code: 'INSUFFICIENT_AMOUNT'
  });
}

// المبلغ النهائي هو المبلغ المدفوع
const finalAmount = amount_paid;

    // 5. إنشاء دفعة واحدة لكل قسط
    const paymentsToInsert = pendingSchedules.map(async (schedule) => {
      const payment = {
        id: uuidv4(),
        schedule_id: schedule.id,
        plan_id: plan_id,
        store_id: storeId,
        received_by: req.user.id,
        amount_paid: schedule.amount, // كل قسط بمبلغه الأصلي
        payment_date: payment_date || new Date().toISOString().split('T')[0],
        is_early: true,
        receipt_number: `RCP-${storeId.slice(0, 8)}-${Date.now()}-${schedule.installment_no}`,
        notes: notes || (discountAmount > 0 ? `تسديد كامل مع تخفيض ${discountAmount.toLocaleString()} ${plan.currency}` : 'تسديد كامل المبلغ'),
        currency: plan.currency,
        created_at: new Date().toISOString()
      };

      // إرسال إشعار وصل الدفع باستخدام القالب
      try {
        // جلب بيانات العميل
        const { data: customerData } = await supabase
          .from('customers')
          .select('full_name, telegram_chat_id')
          .eq('id', plan.customer_id)
          .single();

        if (customerData) {
          const message = await getNotificationText('payment_receipt', {
            customer_name: customerData.full_name,
            amount: schedule.amount,
            currency: plan.currency,
            receipt_no: payment.receipt_number,
            remaining: 0 // في حالة التسديد الكامل
          });

          // إرسال إلى تلجرام إذا كان الزبون لديه chat_id
          if (customerData.telegram_chat_id) {
            await sendTelegramMessage(customerData.telegram_chat_id, message);
            console.log(`📱 تم إرسال إشعار وصل الدفع إلى ${customerData.full_name}`);
          }
        }
      } catch (notificationError) {
        console.error('خطأ في إرسال إشعار الوصل:', notificationError);
      }

      return payment;
    });

    // إدراج جميع الدفعات دفعة واحدة
    const { error: paymentsError } = await supabase
      .from('payments')
      .insert(await Promise.all(paymentsToInsert));

    if (paymentsError) {
      console.error('خطأ في إدراج الدفعات:', paymentsError);
      throw paymentsError;
    }

    // 6. تحديث حالة جميع الأقساط إلى paid
    const { error: updateScheduleError } = await supabase
      .from('payment_schedule')
      .update({ status: 'paid' })
      .eq('plan_id', plan_id)
      .eq('status', 'pending');

    if (updateScheduleError) throw updateScheduleError;

    // 7. تحديث خطة الأقساط
    const newTotalPaid = (plan.total_paid || 0) + totalPendingAmount;
    const newRemainingAmount = plan.total_price - plan.down_payment - newTotalPaid;

    const { error: updatePlanError } = await supabase
      .from('installment_plans')
      .update({
        total_paid: newTotalPaid,
        remaining_amount: Math.max(0, newRemainingAmount),
        status: newRemainingAmount <= 0 ? 'completed' : 'active',
        updated_at: new Date().toISOString()
      })
      .eq('id', plan_id);

    if (updatePlanError) throw updatePlanError;

    // تسجيل العملية
    await logAudit(req, 'UPDATE', 'installment_plans', plan_id, plan, { status: 'completed', total_paid: newTotalPaid });

    res.json({
      success: true,
      data: {
        plan_id,
        total_pending: pendingSchedules.length,
        total_amount: totalPendingAmount,
        discount_amount: discountAmount,
        final_amount: finalAmount,
        receipt_numbers: paymentsToInsert.map(p => p.receipt_number)
      },
      message: `تم تسديد ${pendingSchedules.length} قسط بنجاح${discountAmount > 0 ? ` مع تخفيض ${discountAmount.toLocaleString()} ${plan.currency}` : ''}` 
    });
  } catch (error) {
    console.error('خطأ في التسديد الكامل:', error);
    res.status(500).json({
      success: false,
      error: 'حدث خطأ في الخادم',
      code: 'INTERNAL_ERROR'
    });
  }
});

module.exports = router;
