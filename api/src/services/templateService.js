const { supabase } = require('../config/supabase');

// جلب قالب حسب النوع
const getTemplate = async (type) => {
  const { data, error } = await supabase
    .from('notification_templates')
    .select('body')
    .eq('type', type)
    .eq('is_active', true)
    .single();
  
  if (error || !data) {
    console.log(`⚠️ لم يتم العثور على قالب للنوع: ${type}, سيتم استخدام النص الافتراضي`);
    return null;
  }
  
  return data.body;
};

// استبدال المتغيرات في القالب
const renderTemplate = (template, variables) => {
  if (!template) return null;
  
  let rendered = template;
  for (const [key, value] of Object.entries(variables)) {
    const regex = new RegExp(`{${key}}`, 'g');
    rendered = rendered.replace(regex, value !== undefined ? value : '');
  }
  return rendered;
};

// الحصول على نص الإشعار النهائي
const getNotificationText = async (type, variables) => {
  const template = await getTemplate(type);
  if (template) {
    return renderTemplate(template, variables);
  }
  
  // نصوص افتراضية في حالة عدم وجود قالب
  const fallbacks = {
    reminder: `🔔 تذكير بقسط مستحق\n\nالعميل: ${variables.customer_name}\nالمبلغ: ${variables.amount} ${variables.currency}\nتاريخ الاستحقاق: ${variables.due_date}\n\nيرجى الاستعداد للسداد.`,
    due: `💰 قسط مستحق اليوم\n\nالعميل: ${variables.customer_name}\nالمبلغ: ${variables.amount} ${variables.currency}\nتاريخ الاستحقاق: ${variables.due_date}\n\nيرجى تسديد القسط اليوم.`,
    overdue: `⚠️ قسط متأخر\n\nالعميل: ${variables.customer_name}\nالمبلغ: ${variables.amount} ${variables.currency}\nتاريخ الاستحقاق: ${variables.due_date}\n\nيرجى تسديد القسط المتأخر فوراً.`,
    expiry: `🔔 تنبيه انتهاء اشتراك\n\nمحل: ${variables.store_name}\nمتبقي: ${variables.days_left} أيام\n\nيرجى تجديد الاشتراك.`,
    payment_receipt: `✅ تم استلام الدفعة\n\nالعميل: ${variables.customer_name}\nالمبلغ: ${variables.amount} ${variables.currency}\nرقم الوصل: ${variables.receipt_no}\nالمتبقي: ${variables.remaining} ${variables.currency}` 
  };
  
  return fallbacks[type] || template;
};

module.exports = { getTemplate, renderTemplate, getNotificationText };
