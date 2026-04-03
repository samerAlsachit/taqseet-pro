const cron = require('node-cron');
const { supabase } = require('../config/supabase');
const { uploadToStorage, cleanOldBackups } = require('../services/storageService');
const fs = require('fs');
const path = require('path');

const createBackup = async () => {
  try {
    const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
    const filename = `backup_auto_${timestamp}.json`;
    
    // جلب جميع البيانات
    const tables = ['customers', 'products', 'installment_plans', 'payment_schedule', 'payments', 'users', 'stores'];
    const backupData = {};
    
    for (const table of tables) {
      const { data, error } = await supabase.from(table).select('*');
      if (!error) {
        backupData[table] = data;
      }
    }
    
    const fileContent = JSON.stringify(backupData, null, 2);
    
    // رفع مباشرة إلى Supabase Storage (بدون حفظ محلي)
    const result = await uploadToStorage(null, filename, fileContent);
    
    if (result.success) {
      console.log(`✅ تم إنشاء نسخة احتياطية تلقائية: ${filename}`);
      await cleanOldBackups(30);
    } else {
      console.log(`❌ فشل في إنشاء النسخة: ${result.error}`);
    }
  } catch (error) {
    console.error('❌ خطأ في النسخ الاحتياطي التلقائي:', error);
  }
};

// جدولة المهمة: كل يوم في الساعة 2:00 صباحاً
cron.schedule('0 2 * * *', createBackup, {
  scheduled: true,
  timezone: 'Asia/Baghdad'
});

console.log('✅ [CRON] تم تفعيل مهمة النسخ الاحتياطي التلقائي (كل يوم 2:00 صباحاً) إلى Supabase Storage');

module.exports = { createBackup };
