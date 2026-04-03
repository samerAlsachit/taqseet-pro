const express = require('express');
const { supabase, supabaseAdmin } = require('../config/supabase');
const { listBackups, uploadToStorage, cleanOldBackups } = require('../services/storageService');
const { requireSuperAdmin } = require('../middleware/auth');

const router = express.Router();

// GET /api/admin/backups
router.get('/backups', requireSuperAdmin, async (req, res) => {
  try {
    const backups = await listBackups();
    res.json({ success: true, data: backups });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// POST /api/admin/backups
router.post('/backups', requireSuperAdmin, async (req, res) => {
  console.log('🚀 دالة POST /backups بدأت العمل');
  
  try {
    const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
    const filename = `backup_manual_${timestamp}.json`;
    
    console.log('📦 بدء إنشاء نسخة احتياطية...');
    
    const tables = ['customers', 'products', 'installment_plans', 'payment_schedule', 'payments', 'users', 'stores'];
    const backupData = {};
    
    for (const table of tables) {
      console.log(`  📥 جلب بيانات جدول ${table}...`);
      const { data, error } = await supabase.from(table).select('*');
      if (!error) {
        backupData[table] = data;
        console.log(`     ✅ تم جلب ${data?.length || 0} سجل`);
      } else {
        console.log(`     ❌ فشل في جلب جدول ${table}:`, error.message);
      }
    }
    
    const fileContent = JSON.stringify(backupData, null, 2);
    console.log(`📄 حجم الملف: ${(fileContent.length / 1024).toFixed(2)} KB`);
    
    console.log(`📤 محاولة رفع الملف...`);
    const result = await uploadToStorage(null, filename, fileContent);
    console.log('� نتيجة الرفع:', result);
    
    if (result.success) {
      console.log(`✅ تم رفع الملف بنجاح: ${filename}`);
      await cleanOldBackups(30);
      
      // تسجيل العملية (بدون استخدام جدول backup)
      await logAudit(req, 'CREATE_BACKUP', 'system', null, null, { filename });
      
      res.json({ success: true, data: { filename }, message: 'تم إنشاء النسخة الاحتياطية بنجاح' });
    } else {
      console.log(`❌ فشل في رفع الملف: ${result.error}`);
      res.status(500).json({ success: false, error: result.error });
    }
  } catch (error) {
    console.error('❌ خطأ في إنشاء النسخة:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

// GET /api/admin/backups/:filename - تحميل نسخة
router.get('/backups/:filename', requireSuperAdmin, async (req, res) => {
  try {
    const { filename } = req.params;
    const { data, error } = await supabaseAdmin
      .storage
      .from('backups')
      .download(filename);
    
    if (error) throw error;
    
    res.setHeader('Content-Type', 'application/json');
    res.setHeader('Content-Disposition', `attachment; filename="${filename}"`);
    res.send(data);
  } catch (error) {
    res.status(404).json({ success: false, error: 'الملف غير موجود' });
  }
});

// DELETE /api/admin/backups/:filename
router.delete('/backups/:filename', requireSuperAdmin, async (req, res) => {
  try {
    const { filename } = req.params;
    const { error } = await supabaseAdmin
      .storage
      .from('backups')
      .remove([filename]);
    
    if (error) throw error;
    
    res.json({ success: true, message: 'تم حذف النسخة بنجاح' });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

module.exports = router;
