const moment = require('moment');

/**
 * حساب جدول الأقساط
 * @param {Object} params - معلمات الحساب
 * @param {number} params.totalPrice - السعر الإجمالي
 * @param {number} params.downPayment - المقدمة (0 إذا لم توجد)
 * @param {number} params.installmentAmount - مبلغ القسط المطلوب
 * @param {string} params.frequency - تكرار القسط ('daily' | 'weekly' | 'monthly')
 * @param {string} params.startDate - تاريخ البدء (YYYY-MM-DD)
 * @param {string} params.currency - العملة ('IQD' | 'USD')
 * @returns {Object} نتيجة الحساب مع جدول الأقساط
 */
const calculateInstallments = (params) => {
  const {
    totalPrice,
    downPayment = 0,
    installmentAmount,
    frequency,
    startDate,
    currency = 'IQD'
  } = params;

  // التحقق من المدخلات
  if (!totalPrice || !installmentAmount || !frequency || !startDate) {
    throw new Error('جميع المعلمات المطلوبة يجب أن توفر');
  }

  if (totalPrice <= 0 || installmentAmount <= 0 || downPayment < 0) {
    throw new Error('القيم يجب أن تكون موجبة');
  }

  if (downPayment >= totalPrice) {
    throw new Error('المقدمة يجب أن تكون أقل من السعر الإجمالي');
  }

  // حساب المبلغ الممول
  const financedAmount = totalPrice - downPayment;

  // حساب عدد الأقساط
  const installmentsCount = Math.ceil(financedAmount / installmentAmount);

  // حساب مبلغ القسط الأخير (يستوعب الكسور)
  const lastInstallmentAmount = financedAmount - (installmentAmount * (installmentsCount - 1));

  // حساب تاريخ الانتهاء
  let endDate;
  const start = moment(startDate);

  switch (frequency) {
    case 'daily':
      endDate = start.clone().add(installmentsCount - 1, 'days');
      break;
    case 'weekly':
      endDate = start.clone().add((installmentsCount - 1) * 7, 'days');
      break;
    case 'monthly':
      endDate = start.clone().add(installmentsCount - 1, 'months');
      break;
    default:
      throw new Error('تكرار الأقساط غير صالح');
  }

  // إنشاء جدول الأقساط
  const schedule = [];
  let currentDate = start.clone();

  for (let i = 1; i <= installmentsCount; i++) {
    const amount = i === installmentsCount ? lastInstallmentAmount : installmentAmount;
    
    schedule.push({
      installment_no: i,
      due_date: currentDate.format('YYYY-MM-DD'),
      amount: parseFloat(amount.toFixed(2)),
      currency
    });

    // الانتقال للتاريخ التالي
    switch (frequency) {
      case 'daily':
        currentDate.add(1, 'day');
        break;
      case 'weekly':
        currentDate.add(7, 'days');
        break;
      case 'monthly':
        currentDate.add(1, 'month');
        break;
    }
  }

  return {
    financedAmount: parseFloat(financedAmount.toFixed(2)),
    installmentsCount,
    installmentAmount: parseFloat(installmentAmount.toFixed(2)),
    lastInstallmentAmount: parseFloat(lastInstallmentAmount.toFixed(2)),
    startDate,
    endDate: endDate.format('YYYY-MM-DD'),
    frequency,
    currency,
    schedule
  };
};

/**
 * حساب ملخص خطة الأقساط
 * @param {Object} plan - بيانات خطة الأقساط
 * @param {Array} installments - قائمة الأقساط
 * @returns {Object} ملخص الخطة
 */
const calculatePlanSummary = (plan, installments = []) => {
  const totalAmount = plan.total_amount || 0;
  const downPayment = plan.down_payment || 0;
  const financedAmount = totalAmount - downPayment;

  let totalPaid = 0;
  let pendingCount = 0;
  let overdueCount = 0;
  let paidCount = 0;
  let nextDueDate = null;
  let nextDueAmount = 0;

  const today = moment().format('YYYY-MM-DD');

  installments.forEach(installment => {
    const amount = installment.amount || 0;
    const paidAmount = installment.paid_amount || 0;
    const status = installment.status;
    const dueDate = installment.due_date;

    totalPaid += paidAmount;

    switch (status) {
      case 'pending':
        pendingCount++;
        if (!nextDueDate || moment(dueDate).isBefore(moment(nextDueDate))) {
          nextDueDate = dueDate;
          nextDueAmount = amount - paidAmount;
        }
        break;
      case 'overdue':
        overdueCount++;
        if (!nextDueDate || moment(dueDate).isBefore(moment(nextDueDate))) {
          nextDueDate = dueDate;
          nextDueAmount = amount - paidAmount;
        }
        break;
      case 'paid':
        paidCount++;
        break;
    }
  });

  const remainingBalance = financedAmount - totalPaid;
  const progressPercentage = financedAmount > 0 ? (totalPaid / financedAmount) * 100 : 0;

  return {
    total_amount: totalAmount,
    down_payment: downPayment,
    financed_amount: financedAmount,
    total_paid: totalPaid,
    remaining_balance: remainingBalance,
    progress_percentage: parseFloat(progressPercentage.toFixed(2)),
    installments_summary: {
      total: installments.length,
      paid: paidCount,
      pending: pendingCount,
      overdue: overdueCount
    },
    next_payment: nextDueDate ? {
      due_date: nextDueDate,
      amount: parseFloat(nextDueAmount.toFixed(2))
    } : null
  };
};

/**
 * تحديث حالة الأقساط تلقائياً
 * @param {Array} installments - قائمة الأقساط
 * @returns {Array} الأقساط المحدثة
 */
const updateInstallmentsStatus = (installments) => {
  const today = moment().format('YYYY-MM-DD');

  return installments.map(installment => {
    const dueDate = installment.due_date;
    const paidAmount = installment.paid_amount || 0;
    const totalAmount = installment.amount || 0;

    // إذا تم دفع القسط بالكامل
    if (paidAmount >= totalAmount) {
      return { ...installment, status: 'paid' };
    }

    // إذا تجاوز تاريخ الاستحقاق ولم يتم الدفع
    if (moment(dueDate).isBefore(today, 'day')) {
      return { ...installment, status: 'overdue' };
    }

    // القسط مستحق ولكن لم يحل وقت استحقاقه بعد
    return { ...installment, status: 'pending' };
  });
};

module.exports = {
  calculateInstallments,
  calculatePlanSummary,
  updateInstallmentsStatus
};
