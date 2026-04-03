const { supabaseAdmin } = require('../config/supabase');

const BUCKET_NAME = process.env.SUPABASE_BACKUP_BUCKET || 'backups';

const testConnection = async () => {
  try {
    const { data, error } = await supabaseAdmin.storage.listBuckets();
    if (error) {
      console.error('❌ فشل الاتصال بـ Supabase Storage:', error);
    } else {
      console.log('✅ الاتصال بـ Supabase Storage ناجح، عدد البكتات:', data?.length);
    }
  } catch (e) {
    console.error('❌ خطأ في الاتصال:', e.message);
  }
};

testConnection();

// رفع ملف إلى Supabase Storage
const uploadToStorage = async (filePath, fileName, fileContent) => {
  try {
    const BUCKET_NAME = process.env.SUPABASE_BACKUP_BUCKET || 'backups';
    
    console.log('📤 رفع إلى bucket:', BUCKET_NAME);
    console.log('📄 حجم الملف:', fileContent.length);
    
    const { data, error } = await supabaseAdmin
      .storage
      .from(BUCKET_NAME)
      .upload(fileName, fileContent, {
        contentType: 'application/json',
        upsert: false
      });

    if (error) {
      console.error('❌ خطأ من Supabase:', error);
      return { success: false, error: error.message };
    }

    console.log('✅ تم الرفع بنجاح:', data);
    return { success: true, path: data.path };
  } catch (error) {
    console.error('❌ خطأ في رفع الملف:', error.message);
    return { success: false, error: error.message };
  }
};

// حذف الملفات القديمة من Storage
const cleanOldBackups = async (keepCount = 30) => {
  try {
    const { data: files, error } = await supabaseAdmin
      .storage
      .from(BUCKET_NAME)
      .list();

    if (error) throw error;

    // تصفية الملفات التي تبدأ بـ backup_
    const backupFiles = files
      .filter(file => file.name.startsWith('backup_') && file.name.endsWith('.json'))
      .sort((a, b) => new Date(b.created_at) - new Date(a.created_at));

    // حذف الملفات القديمة
    for (let i = keepCount; i < backupFiles.length; i++) {
      await supabaseAdmin
        .storage
        .from(BUCKET_NAME)
        .remove([backupFiles[i].name]);
      console.log(`🗑️ تم حذف نسخة قديمة: ${backupFiles[i].name}`);
    }
  } catch (error) {
    console.error('❌ خطأ في تنظيف الملفات القديمة:', error.message);
  }
};

// جلب قائمة النسخ الاحتياطية
const listBackups = async () => {
  try {
    const { data: files, error } = await supabaseAdmin
      .storage
      .from(BUCKET_NAME)
      .list();

    if (error) throw error;

    return files
      .filter(file => file.name.startsWith('backup_') && file.name.endsWith('.json'))
      .map(file => ({
        name: file.name,
        size: file.metadata?.size || 0,
        created_at: file.created_at,
        id: file.id
      }))
      .sort((a, b) => new Date(b.created_at) - new Date(a.created_at));
  } catch (error) {
    console.error('خطأ في جلب قائمة النسخ:', error.message);
    return [];
  }
};

module.exports = { uploadToStorage, cleanOldBackups, listBackups };
