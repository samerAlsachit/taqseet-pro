const axios = require('axios');

const BOT_TOKEN = process.env.TELEGRAM_BOT_TOKEN;
const BASE_URL = `https://api.telegram.org/bot${BOT_TOKEN}`;

// إرسال رسالة نصية
const sendMessage = async (chatId, text) => {
  try {
    const response = await axios.post(`${BASE_URL}/sendMessage`, {
      chat_id: chatId,
      text: text,
      parse_mode: 'HTML'
    });
    console.log('📱 تم إرسال رسالة تلجرام بنجاح');
    return response.data;
  } catch (error) {
    console.error('❌ خطأ في إرسال رسالة تلجرام:', error.response?.data || error.message);
    return null;
  }
};

// إرسال رسالة مع زر
const sendMessageWithButton = async (chatId, text, buttonText, buttonUrl) => {
  try {
    const response = await axios.post(`${BASE_URL}/sendMessage`, {
      chat_id: chatId,
      text: text,
      parse_mode: 'HTML',
      reply_markup: {
        inline_keyboard: [[{ text: buttonText, url: buttonUrl }]]
      }
    });
    console.log('📱 تم إرسال رسالة تلجرام مع زر بنجاح');
    return response.data;
  } catch (error) {
    console.error('❌ خطأ في إرسال رسالة تلجرام:', error.response?.data || error.message);
    return null;
  }
};

// إرسال إشعار انتهاء الاشتراك
const sendExpiryNotification = async (chatId, storeName, daysLeft) => {
  const message = `
🔔 <b>تنبيه انتهاء اشتراك</b>

مرحباً،
نود إعلامكم بأن اشتراك محل <b>${storeName}</b> على وشك الانتهاء خلال <b>${daysLeft} أيام</b>.

يرجى التواصل مع الدعم لتجديد الاشتراك.

📞 هاتف: 077XXXXXXXX
📧 بريد: support@marsat.com

شكراً لثقتكم بنا
<b>مرساة</b>
  `;
  return await sendMessage(chatId, message);
};

// إرسال إشعار قسط مستحق
const sendDueNotification = async (chatId, customerName, amount, dueDate, planId) => {
  const message = `
💰 <b>تذكير بقسط مستحق</b>

العميل: <b>${customerName}</b>
المبلغ: <b>${amount.toLocaleString()} IQD</b>
تاريخ الاستحقاق: <b>${new Date(dueDate).toLocaleDateString('ar-IQ')}</b>

يرجى متابعة التحصيل.
  `;
  const buttonUrl = `${process.env.FRONTEND_URL}/installments/${planId}`;
  return await sendMessageWithButton(chatId, message, 'عرض التفاصيل', buttonUrl);
};

module.exports = {
  sendMessage,
  sendMessageWithButton,
  sendExpiryNotification,
  sendDueNotification
};
