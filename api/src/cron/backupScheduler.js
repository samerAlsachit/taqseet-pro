const cron = require('node-cron');
const { supabase } = require('../config/supabase');
const fs = require('fs');
const path = require('path');

const createBackup = async () => {
  try {
    const backupsDir = path.join(__dirname, '../../backups');
    if (!fs.existsSync(backupsDir)) {
      fs.mkdirSync(backupsDir, { recursive: true });
    }
    
    const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
    const filename = `backup_auto_${timestamp}.json`;
    const filepath = path.join(backupsDir, filename);
    
    // جلب جميع البيانات
    const tables = ['customers', 'products', 'installment_plans', 'payment_schedule', 'payments', 'users', 'stores'];
    const backupData = {};
    
    for (const table of tables) {
      const { data, error } = await supabase.from(table).select('*');
      if (!error) {
        backupData[table] = data;
      }
    }
    
    fs.writeFileSync(filepath, JSON.stringify(backupData, null, 2));
    console.log(`✅ تم إنشاء نسخة احتياطية تلقائية: ${filename}`);
    
    // حذف النسخ القديمة (الاحتفاظ بآخر 30)
    const files = fs.readdirSync(backupsDir);
    const backups = files
      .filter(file => file.startsWith('backup_auto_') && file.endsWith('.json'))
      .map(file => ({ name: file, path: path.join(backupsDir, file) }))
      .sort((a, b) => fs.statSync(b.path).birthtimeMs - fs.statSync(a.path).birthtimeMs);
    
    for (let i = 30; i < backups.length; i++) {
      fs.unlinkSync(backups[i].path);
      console.log(`🗑️ تم حذف نسخة قديمة: ${backups[i].name}`);
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

console.log('✅ [CRON] تم تفعيل مهمة النسخ الاحتياطي التلقائي (كل يوم 2:00 صباحاً)');

module.exports = { createBackup };
