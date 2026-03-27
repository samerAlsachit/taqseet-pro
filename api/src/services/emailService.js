const { Resend } = require('resend');

const resend = new Resend(process.env.RESEND_API_KEY);

const sendPasswordResetEmail = async (to, username, resetUrl) => {
  try {
    const { data, error } = await resend.emails.send({
      from: 'مرساة <onboarding@resend.dev>',
      to: [to],
      subject: 'إعادة تعيين كلمة المرور - مرساة',
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
          <p style="color: #333;"><strong>${username}</strong></p>
          <p style="color: #333;">لقد تلقينا طلباً لإعادة تعيين كلمة المرور الخاصة بحسابك.</p>
          <p style="color: #333;">لإعادة تعيين كلمة المرور، اضغط على الرابط أدناه:</p>
          
          <div style="text-align: center; margin: 25px 0;">
            <a href="${resetUrl}" style="background-color: #3A86FF; color: white; padding: 12px 24px; text-decoration: none; border-radius: 8px; display: inline-block;">
              إعادة تعيين كلمة المرور
            </a>
          </div>
          
          <p style="color: #666; font-size: 14px;">هذا الرابط صالح لمدة ساعة واحدة.</p>
          <p style="color: #666; font-size: 14px;">إذا لم تطلب إعادة تعيين كلمة المرور، يمكنك تجاهل هذا البريد.</p>
          
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
      console.error('خطأ في إرسال البريد:', error);
      return { success: false, error };
    }
    return { success: true, data };
  } catch (error) {
    console.error('خطأ في إرسال البريد:', error);
    return { success: false, error };
  }
};

const sendUsernameReminder = async (to, username, storeName) => {
  try {
    const { data, error } = await resend.emails.send({
      from: 'مرساة <onboarding@resend.dev>',
      to: [to],
      subject: 'تذكير باسم المستخدم - مرساة',
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
          <p style="color: #333;">لقد تلقينا طلباً لتذكيرك باسم المستخدم الخاص بحسابك.</p>
          
          <div style="background: #F8F9FA; padding: 15px; border-radius: 8px; margin: 20px 0;">
            <p style="margin: 0 0 5px; color: #333;">اسم المستخدم الخاص بك هو:</p>
            <p style="margin: 0; font-size: 20px; font-weight: bold; color: #3A86FF;">${username}</p>
          </div>
          
          <p style="color: #333;">اسم المحل: <strong>${storeName || 'مرساة'}</strong></p>
          <p style="color: #333;">يمكنك استخدام هذا الاسم لتسجيل الدخول إلى حسابك.</p>
          
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
      console.error('خطأ في إرسال البريد:', error);
      return { success: false, error };
    }
    return { success: true, data };
  } catch (error) {
    console.error('خطأ في إرسال البريد:', error);
    return { success: false, error };
  }
};

module.exports = { sendPasswordResetEmail, sendUsernameReminder };
