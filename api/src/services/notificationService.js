const { Resend } = require('resend');

const resend = new Resend(process.env.RESEND_API_KEY);

// إرسال إشعار واتساب (يفتح رابط واتساب للتنبيه)
const sendWhatsAppNotification = (phone, storeName, daysLeft) => {
  const message = `*مرساة - تنبيه انتهاء اشتراك*

السلام عليكم،

نود إعلامكم بأن اشتراك محل "${storeName}" على وشك الانتهاء خلال ${daysLeft} أيام.

يرجى التواصل مع الدعم لتجديد الاشتراك.

📞 هاتف: 077XXXXXXXX
📧 بريد: support@marsat.com

شكراً لثقتكم بنا
مرساة
نظام إدارة الأقساط والديون`;
  
  const encodedMessage = encodeURIComponent(message);
  const whatsappUrl = `https://wa.me/${phone.replace(/[^0-9]/g, '')}?text=${encodedMessage}`;
  return whatsappUrl;
};

// إرسال إشعار إيميل
const sendEmailNotification = async (email, storeName, ownerName, daysLeft) => {
  try {
    const { data, error } = await resend.emails.send({
      from: 'مرساة <onboarding@resend.dev>',
      to: [email],
      subject: 'تنبيه: اشتراكك على وشك الانتهاء - مرساة',
      html: `
        <div dir="rtl" style="font-family: 'Tajawal', Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; background: #fff; border-radius: 12px;">
          <div style="text-align: center; margin-bottom: 20px;">
            <div style="display: inline-block; width: 50px; height: 50px; background: linear-gradient(135deg, #0A192F, #3A86FF); border-radius: 50%; display: flex; align-items: center; justify-content: center; margin-bottom: 10px;">
              <span style="font-size: 24px;">⚓</span>
            </div>
            <h1 style="color: #0A192F; margin: 0; font-size: 24px;">مرساة</h1>
            <p style="color: #666; margin: 5px 0 0;">نظام إدارة الأقساط والديون</p>
          </div>
          
          <p style="color: #333;">السلام عليكم،</p>
          <p style="color: #333;"><strong>${ownerName}</strong></p>
          <p style="color: #333;">نود إعلامكم بأن اشتراك محل <strong>"${storeName}"</strong> على وشك الانتهاء خلال <strong style="color: #FFC107;">${daysLeft} أيام</strong>.</p>
          
          <div style="background: #F8F9FA; padding: 15px; border-radius: 8px; margin: 20px 0;">
            <p style="margin: 0 0 5px; color: #333;">📅 تاريخ الانتهاء: <strong>${new Date().toLocaleDateString('ar-IQ')}</strong></p>
            <p style="margin: 0; color: #333;">⏰ متبقي: <strong>${daysLeft} يوم</strong></p>
          </div>
          
          <p style="color: #333;">يرجى التواصل مع الدعم لتجديد الاشتراك:</p>
          <ul style="color: #666;">
            <li>📞 هاتف: 077XXXXXXXX</li>
            <li>📧 بريد: support@marsat.com</li>
          </ul>
          
          <hr style="margin: 20px 0; border: none; border-top: 1px solid #eee;" />
          
          <p style="color: #666; font-size: 12px; text-align: center;">
            هذا بريد آلي من نظام مرساة، يرجى عدم الرد عليه.
          </p>
          <p style="color: #666; font-size: 12px; text-align: center;">
            © 2026 مرساة - جميع الحقوق محفوظة
          </p>
        </div>
      `,
    });

    if (error) {
      console.error('خطأ في إرسال الإيميل:', error);
      return { success: false, error };
    }
    return { success: true, data };
  } catch (error) {
    console.error('خطأ في إرسال الإيميل:', error);
    return { success: false, error };
  }
};

module.exports = {
  sendWhatsAppNotification,
  sendEmailNotification
};
