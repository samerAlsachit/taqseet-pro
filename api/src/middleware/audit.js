const { supabase } = require('../config/supabase');
const { v4: uuidv4 } = require('uuid');

const logAudit = async (req, action, tableName, recordId, oldData = null, newData = null) => {
  try {
    const userId = req.user?.id || null;
    const storeId = req.user?.store_id || null;
    const ipAddress = req.ip || req.headers['x-forwarded-for'] || req.connection?.remoteAddress || null;
    const userAgent = req.headers['user-agent'] || null;

    console.log('📝 تسجيل عملية:', { action, tableName, recordId, storeId, userId });

    const { error } = await supabase
      .from('audit_logs')
      .insert({
        id: uuidv4(),
        store_id: storeId,
        user_id: userId,
        action,
        table_name: tableName,
        record_id: recordId,
        old_data: oldData,
        new_data: newData,
        ip_address: ipAddress,
        created_at: new Date().toISOString()
        // user_agent: userAgent  // علق هذا السطر مؤقتاً
      });

    if (error) {
      console.error('خطأ في إدخال سجل العمليات:', error);
    }
  } catch (error) {
    console.error('خطأ في تسجيل سجل العمليات:', error);
  }
};

module.exports = { logAudit };
