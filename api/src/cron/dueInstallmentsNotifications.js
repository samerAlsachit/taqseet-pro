const cron = require('node-cron');
const { supabase } = require('../config/supabase');
const { sendTelegramMessage } = require('../services/telegramService');
const { getNotificationText } = require('../services/templateService');

// إرسال إشعارات الأقساط المستحقة للزبائن
const sendDueInstallmentsNotifications = async () => {
  console.log('🕐 [CRON] بدء إرسال إشعارات الأقساط المستحقة...', new Date().toISOString());

  try {
    const today = new Date().toISOString().split('T')[0];
    const tomorrow = new Date();
    tomorrow.setDate(tomorrow.getDate() + 1);
    const tomorrowStr = tomorrow.toISOString().split('T')[0];

    // جلب الأقساط المستحقة اليوم وغداً
    const { data: schedules, error } = await supabase
      .from('payment_schedule')
      .select(`
        *,
        installment_plans!plan_id (
          id,
          customer_id,
          product_name,
          currency,
          customers!customer_id (full_name, phone, telegram_chat_id)
        )
      `)
      .in('due_date', [today, tomorrowStr])
      .eq('status', 'pending');

    if (error) throw error;

    if (!schedules || schedules.length === 0) {
      console.log('لا توجد أقساط مستحقة');
      return;
    }

    console.log(`📋 تم العثور على ${schedules.length} قسط مستحق`);

    for (const schedule of schedules) {
      const plan = schedule.installment_plans;
      const customer = plan?.customers;
      
      if (!customer || !customer.telegram_chat_id) continue;
      
      const isToday = schedule.due_date === today;
      const templateType = isToday ? 'due' : 'reminder';
      const message = await getNotificationText(templateType, {
        customer_name: customer.full_name,
        amount: schedule.amount,
        currency: plan.currency,
        due_date: new Date(schedule.due_date).toLocaleDateString('ar-IQ')
      });
      
      await sendTelegramMessage(customer.telegram_chat_id, message);
      console.log(`📱 تم إرسال إشعار إلى ${customer.full_name}`);
    }
  } catch (error) {
    console.error('❌ خطأ في إرسال إشعارات الأقساط:', error);
  }
};

// جدولة المهمة: كل يوم في الساعة 8:00 صباحاً
cron.schedule('0 8 * * *', sendDueInstallmentsNotifications, {
  scheduled: true,
  timezone: 'Asia/Baghdad'
});

console.log('✅ [CRON] تم تفعيل مهمة إشعارات الأقساط المستحقة (كل يوم 8:00 صباحاً)');

module.exports = { sendDueInstallmentsNotifications };
