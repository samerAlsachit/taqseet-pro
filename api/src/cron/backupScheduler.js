require('dotenv').config({ path: require('path').resolve(__dirname, '../../.env') });

const cron = require('node-cron');
const { supabase, supabaseAdmin } = require('../config/supabase');

const createBackup = async () => {
  try {
    const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
    const filename = `backup_auto_${timestamp}.json`;

    console.log('📦 بدء النسخ الاحتياطي التلقائي...');

    // جلب البيانات من جميع الجداول
    const tables = ['customers', 'products', 'installment_plans', 'payment_schedule', 'payments', 'users', 'stores'];
    const backupData = {};

    for (const table of tables) {
      const { data, error } = await supabase.from(table).select('*');
      if (!error) {
        backupData[table] = data;
        console.log(`  ✅ ${table}: ${data?.length || 0} سجل`);
      } else {
        console.warn(`  ⚠️ فشل جلب ${table}:`, error.message);
      }
    }

    const fileContent = JSON.stringify(backupData, null, 2);
    console.log(`📤 رفع ${filename} إلى Supabase Storage...`);

    // رفع مباشرة إلى Supabase Storage
    const { data, error } = await supabaseAdmin
      .storage
      .from('backups')
      .upload(filename, fileContent, {
        contentType: 'application/json',
        upsert: false
      });

    if (error) {
      console.error('❌ فشل الرفع:', error.message);
      return;
    }

    console.log(`✅ تم إنشاء نسخة احتياطية تلقائية: ${filename}`);

    // حذف النسخ القديمة (الاحتفاظ بآخر 30)
    try {
      const { data: allFiles } = await supabaseAdmin
        .storage
        .from('backups')
        .list('', { sortBy: { column: 'created_at', order: 'desc' } });

      const oldFiles = (allFiles || [])
        .filter(f => f.name.startsWith('backup_auto_') && f.name.endsWith('.json'))
        .slice(30);

      if (oldFiles.length > 0) {
        await supabaseAdmin
          .storage
          .from('backups')
          .remove(oldFiles.map(f => f.name));
        console.log(`🗑️ تم حذف ${oldFiles.length} نسخة قديمة`);
      }
    } catch (cleanupError) {
      console.warn('⚠️ خطأ في تنظيف النسخ القديمة:', cleanupError.message);
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