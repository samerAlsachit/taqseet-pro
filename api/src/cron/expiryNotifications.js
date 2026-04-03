const cron = require('node-cron');
const { supabase } = require('../config/supabase');
const { sendWhatsAppNotification, sendEmailNotification } = require('../services/notificationService');
const { sendExpiryNotification } = require('../services/telegramService');
const { getNotificationText } = require('../services/templateService');

// دالة مساعدة لإنشاء رسالة انتهاء الاشتراك
const generateExpiryMessage = (storeName, daysLeft) => {
  return `
🔔 <b>تنبيه انتهاء اشتراك</b>

مرحباً،
نود إعلامكم بأن اشتراك محل <b>${storeName}</b> على وشك الانتهاء خلال <b>${daysLeft} أيام</b>.

يرجى التواصل مع الدعم لتجديد الاشتراك.

📞 هاتف: 077XXXXXXXX
📧 بريد: support@marsat.com

شكراً لثقتكم بنا
<b>مرساة</b>
  `.trim();
};

// دالة مساعدة لإرسال رسالة إلى تاجر بناءً على رقم هاتفه
const sendTelegramByPhone = async (phone, message) => {
  // البحث عن التاجر بهذا الرقم
  const { data: stores } = await supabase
    .from('stores')
    .select('telegram_chat_id, name')
    .ilike('phone', `%${phone}%`);

  if (stores && stores.length > 0) {
    for (const store of stores) {
      if (store.telegram_chat_id) {
        await sendExpiryNotification(store.telegram_chat_id, store.name, 7); // استخدام الدالة الأصلية
        console.log(`📱 تم إرسال إشعار تلجرام إلى ${store.name}`);
      }
    }
  } else {
    console.log(`⚠️ لا يوجد تاجر مسجل بهذا الرقم: ${phone}`);
  }
};

// وظيفة إرسال التنبيهات
const sendExpiryNotifications = async () => {
  console.log('🕐 [CRON] بدء إرسال تنبيهات انتهاء الاشتراك...', new Date().toISOString());

  try {
    const today = new Date();
    const nextWeek = new Date();
    nextWeek.setDate(today.getDate() + 7);
    
    const todayStr = today.toISOString().split('T')[0];
    const nextWeekStr = nextWeek.toISOString().split('T')[0];

    // جلب المحلات مع إعدادات الإشعارات
    const { data: stores, error } = await supabase
      .from('stores')
      .select('id, name, owner_name, phone, email, subscription_end, notification_settings')
      .lt('subscription_end', nextWeekStr)
      .gte('subscription_end', todayStr)
      .eq('is_active', true);

    if (error) throw error;

    if (!stores || stores.length === 0) {
      console.log('لا توجد محلات على وشك الانتهاء');
      return;
    }

    console.log(`📋 تم العثور على ${stores.length} محل على وشك الانتهاء`);

    for (const store of stores) {
      const daysLeft = Math.ceil(
        (new Date(store.subscription_end).getTime() - today.getTime()) / 
        (1000 * 60 * 60 * 24)
      );

      // التحقق من إعدادات الإشعارات
      const settings = store.notification_settings || {};
      
      // إرسال إشعار تلجرام إذا كان مفعلاً
      if (settings.telegram_enabled !== false && store.phone) {
        const message = await getNotificationText('expiry', {
          store_name: store.name,
          days_left: daysLeft
        });
        await sendTelegramByPhone(store.phone, message);
        console.log(`   📱 تم إرسال إشعار تلجرام إلى ${store.name}`);
      }
      
      // إرسال إشعار واتساب إذا كان مفعلاً
      if (settings.whatsapp_enabled && store.phone) {
        const message = await getNotificationText('expiry', {
          store_name: store.name,
          days_left: daysLeft
        });
        const whatsappUrl = sendWhatsAppNotification(store.phone, message);
        console.log(`   📱 واتساب: ${whatsappUrl}`);
      }
      
      // إرسال إشعار إيميل إذا كان مفعلاً
      if (settings.email_enabled !== false && store.email) {
        const message = await getNotificationText('expiry', {
          store_name: store.name,
          days_left: daysLeft
        });
        const result = await sendEmailNotification(store.email, message);
        if (result.success) {
          console.log(`   📧 إيميل: تم الإرسال إلى ${store.email}`);
        }
      }
    }
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
