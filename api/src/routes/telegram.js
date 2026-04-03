const express = require('express');
const router = express.Router();
const { supabase } = require('../config/supabase');

// تخزين مؤقت لاختيارات المستخدمين
const tempStoreSelections = {};

const sendTelegramMessage = async (chatId, text) => {
  const token = process.env.TELEGRAM_BOT_TOKEN;
  const url = `https://api.telegram.org/bot${token}/sendMessage`;
  
  console.log('📤 محاولة إرسال:', { chatId, textLength: text.length });
  console.log('� URL:', url.substring(0, 50) + '...');
  
  try {
    const response = await fetch(url, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ 
        chat_id: chatId, 
        text: text, 
        parse_mode: 'HTML' 
      })
    });
    
    const result = await response.json();
    console.log('📥 الرد الكامل من تلجرام:', JSON.stringify(result, null, 2));
    
    if (!result.ok) {
      console.error('❌ فشل الإرسال:', result.description);
    } else {
      console.log('✅ تم الإرسال بنجاح');
    }
    
    return result;
  } catch (error) {
    console.error('❌ خطأ في الاتصال:', error.message);
    return null;
  }
};

router.post('/webhook', async (req, res) => {
  try {
    const { message } = req.body;
    
    if (!message || !message.text || !message.chat) {
      return res.sendStatus(200);
    }

    const chatId = message.chat.id;
    const text = message.text.trim();
    
    // التحقق إذا كان المستخدم في حالة اختيار حساب
    if (tempStoreSelections[chatId]) {
      const accounts = tempStoreSelections[chatId];
      const selectedIndex = parseInt(text) - 1;
      
      if (selectedIndex >= 0 && selectedIndex < accounts.length) {
        const selectedAccount = accounts[selectedIndex];
        const table = selectedAccount.type === 'store' ? 'stores' : 'customers';
        const { error } = await supabase
          .from(table)
          .update({ telegram_chat_id: chatId })
          .eq('id', selectedAccount.id);
        
        if (error) {
          await sendTelegramMessage(chatId, `❌ حدث خطأ: ${error.message}`);
        } else {
          await sendTelegramMessage(chatId, `✅ تم ربط حسابك مع ${selectedAccount.displayName} بنجاح!\n\nستستقبل إشعارات ${selectedAccount.type === 'store' ? 'انتهاء الاشتراك' : 'الأقساط المستحقة'} تلقائياً.`);
        }
        
        delete tempStoreSelections[chatId];
      } else {
        await sendTelegramMessage(chatId, `❌ اختيار غير صحيح. يرجى إرسال رقم بين 1 و ${accounts.length}`);
      }
      return res.sendStatus(200);
    }
    
    // استخراج رقم الهاتف
    const phone = text.replace(/[^0-9]/g, '');
    
    if (phone.length < 10) {
      await sendTelegramMessage(chatId, `❌ يرجى إرسال رقم هاتف صحيح (10 أرقام على الأقل).\nمثال: 07701234567`);
      return res.sendStatus(200);
    }

    // 1. البحث عن جميع المحلات بهذا الرقم
    console.log('🔍 البحث عن رقم:', phone);
    console.log('🔍 في جدول stores...');
    const { data: stores } = await supabase
      .from('stores')
      .select('id, name, telegram_chat_id')
      .ilike('phone', `%${phone}%`);
    console.log('نتيجة stores:', stores);

    console.log('🔍 في جدول customers...');
    const { data: customers } = await supabase
      .from('customers')
      .select('id, full_name, telegram_chat_id')
      .ilike('phone', `%${phone}%`);
    console.log('نتيجة customers:', customers);

    // دمج النتائج
    const allAccounts = [
      ...(stores || []).map(s => ({ ...s, type: 'store', displayName: s.name })),
      ...(customers || []).map(c => ({ ...c, type: 'customer', displayName: c.full_name }))
    ];

    if (allAccounts.length > 0) {
      if (allAccounts.length === 1) {
        // حساب واحد → ربط تلقائي
        const account = allAccounts[0];
        const table = account.type === 'store' ? 'stores' : 'customers';
        await supabase
          .from(table)
          .update({ telegram_chat_id: chatId })
          .eq('id', account.id);
        
        await sendTelegramMessage(chatId, `✅ مرحباً ${account.displayName}!\n\nتم ربط حسابك بنجاح.`);
      } else {
        // عدة حسابات → عرض الخيارات
        let message = `🔍 تم العثور على ${allAccounts.length} حساب مرتبط برقم هاتفك:\n\n`;
        allAccounts.forEach((acc, index) => {
          message += `${index + 1}. ${acc.displayName} (${acc.type === 'store' ? 'محل' : 'زبون'})\n`;
        });
        message += `\nيرجى إرسال رقم الحساب الذي تريد ربطه (1-${allAccounts.length})`;
        
        tempStoreSelections[chatId] = allAccounts;
        await sendTelegramMessage(chatId, message);
      }
      return res.sendStatus(200);
    }

    // لم يتم العثور على مستخدم
    await sendTelegramMessage(chatId, `❌ عذراً، لم نتمكن من العثور على حساب مرتبط برقم الهاتف: ${phone}\n\nيرجى التأكد من الرقم والمحاولة مرة أخرى، أو التواصل مع الدعم.`);
    
    res.sendStatus(200);
  } catch (error) {
    console.error('❌ خطأ في webhook:', error);
    res.sendStatus(500);
  }
});

router.get('/test/:chatId', async (req, res) => {
  const { chatId } = req.params;
  await sendTelegramMessage(chatId, '🔔 هذه رسالة تجريبية من نظام مرساة');
  res.json({ success: true });
});

// إرسال رسالة إلى جميع المستخدمين المرتبطين برقم هاتف معين
router.post('/test-by-phone', async (req, res) => {
  console.log("✅ تم استدعاء endpoint /test-by-phone");
  const { phone, message } = req.body;
  
  console.log('📞 رقم الهاتف المستلم:', phone);
  console.log('💬 الرسالة:', message);
  
  try {
    if (!phone) {
      return res.status(400).json({ error: 'رقم الهاتف مطلوب' });
    }
    
    // البحث عن جميع المحلات بهذا الرقم (بدلاً من single)
    const { data: stores } = await supabase
      .from('stores')
      .select('telegram_chat_id, name, id')
      .ilike('phone', `%${phone}%`);

    console.log('🔍 عدد المحلات التي تم العثور عليها:', stores?.length);

    if (stores && stores.length > 0) {
      // إذا كان هناك عدة محلات، أرسل إلى أول واحد (أو يمكنك إرسال إلى الكل)
      for (const store of stores) {
        if (store.telegram_chat_id) {
          await sendTelegramMessage(store.telegram_chat_id, message || `🔔 رسالة تجريبية لنظام مرساة`);
          console.log(`✅ تم إرسال رسالة إلى التاجر ${store.name}`);
        }
      }
    }
    
    // البحث عن الزبون بهذا الرقم
    const { data: customer } = await supabase
      .from('customers')
      .select('telegram_chat_id, full_name')
      .ilike('phone', `%${phone}%`)
      .single();
    
    console.log('🔍 نتيجة البحث عن زبون:', customer);

    if (customer?.telegram_chat_id) {
      console.log('📤 سيتم إرسال رسالة إلى الزبون:', customer.full_name);
      await sendTelegramMessage(customer.telegram_chat_id, message || `🔔 رسالة تجريبية لنظام مرساة`);
      console.log(`✅ تم إرسال رسالة إلى الزبون ${customer.full_name}`);
    } else {
      console.log('⚠️ لا يوجد زبون بهذا الرقم أو ليس لديه Chat ID');
    }
    
    res.json({ success: true, message: 'تم إرسال الرسائل' });
  } catch (error) {
    console.error('خطأ:', error);
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;
