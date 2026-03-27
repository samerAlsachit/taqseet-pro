const cron = require('node-cron');
const { supabase } = require('../config/supabase');
const { sendWhatsAppNotification, sendEmailNotification } = require('../services/notificationService');

// وظيفة إرسال التنبيهات
const sendExpiryNotifications = async () => {
  console.log('� [CRON] بدء إرسال تنبيهات انتهاء الاشتراك...', new Date().toISOString());

  try {
    const today = new Date();
    const nextWeek = new Date();
    nextWeek.setDate(today.getDate() + 7);
    
    const todayStr = today.toISOString().split('T')[0];
    const nextWeekStr = nextWeek.toISOString().split('T')[0];

    // جلب المحلات التي تنتهي خلال 7 أيام
    const { data: stores, error } = await supabase
      .from('stores')
      .select('id, name, owner_name, phone, email, subscription_end')
      .lt('subscription_end', nextWeekStr)
      .gte('subscription_end', todayStr)
      .eq('is_active', true);

    if (error) {
      console.error('خطأ في جلب المحلات:', error);
      return;
    }

    if (!stores || stores.length === 0) {
      console.log('لا توجد محلات على وشك الانتهاء');
      return;
    }

    console.log(`📋 تم العثور على ${stores.length} محل على وشك الانتهاء`);

    let whatsappSent = 0;
    let emailSent = 0;
    let failed = 0;

    for (const store of stores) {
      const daysLeft = Math.ceil(
        (new Date(store.subscription_end).getTime() - today.getTime()) / 
        (1000 * 60 * 60 * 24)
      );

      console.log(`� معالجة محل: ${store.name} (ينتهي خلال ${daysLeft} أيام)`);

      // إرسال إشعار واتساب (تسجيل الرابط فقط)
      if (store.phone) {
        const whatsappUrl = sendWhatsAppNotification(store.phone, store.name, daysLeft);
        console.log(`   📱 واتساب: ${whatsappUrl}`);
        whatsappSent++;
      }

      // إرسال إشعار إيميل
      if (store.email) {
        const result = await sendEmailNotification(store.email, store.name, store.owner_name, daysLeft);
        if (result.success) {
          console.log(`   📧 إيميل: تم الإرسال إلى ${store.email}`);
          emailSent++;
        } else {
          console.log(`   ❌ إيميل: فشل الإرسال إلى ${store.email}`);
          failed++;
        }
      }

      // تسجيل التنبيه في قاعدة البيانات
      await supabase
        .from('expiry_notifications')
        .insert({
          store_id: store.id,
          days_left: daysLeft,
          sent_at: new Date().toISOString(),
          whatsapp_sent: !!store.phone,
          email_sent: !!store.email
        });
    }

    console.log(`✅ [CRON] اكتمل الإرسال: واتساب=${whatsappSent}, إيميل=${emailSent}, فشل=${failed}`);
  } catch (error) {
    console.error('❌ خطأ في إرسال التنبيهات:', error);
  }
};

// جدولة المهمة: كل يوم في الساعة 9:00 صباحاً
cron.schedule('0 9 * * *', sendExpiryNotifications, {
  scheduled: true,
  timezone: 'Asia/Baghdad' // توقيت بغداد
});

console.log('✅ [CRON] تم تفعيل مهمة إرسال تنبيهات انتهاء الاشتراك (كل يوم 9:00 صباحاً)');

module.exports = { sendExpiryNotifications };
