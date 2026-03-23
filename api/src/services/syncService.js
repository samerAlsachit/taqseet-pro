const { supabase, supabaseAdmin } = require('../config/supabase');
const { v4: uuidv4 } = require('uuid');
const moment = require('moment');

/**
 * التحقق مما إذا كان local_id تمت معالجته مسبقاً
 */
const checkLocalIdExists = async (storeId, localId, tableName) => {
  const { data, error } = await supabase
    .from(tableName)
    .select('id')
    .eq('store_id', storeId)
    .eq('local_id', localId)
    .single();

  return !error && data;
};

/**
 * معالجة عملية INSERT
 */
const handleInsert = async (storeId, operation) => {
  try {
    const { local_id, table_name, payload } = operation;
    
    // التحقق من وجود local_id مسبقاً
    const exists = await checkLocalIdExists(storeId, local_id, table_name);
    if (exists) {
      return {
        success: false,
        reason: 'local_id_exists',
        message: 'السجل موجود مسبقاً',
        local_id
      };
    }

    // إضافة البيانات المطلوبة
    const recordData = {
      ...payload,
      id: uuidv4(),
      store_id: storeId,
      local_id: local_id,
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString()
    };

    const { data, error } = await supabaseAdmin
      .from(table_name)
      .insert(recordData)
      .select()
      .single();

    if (error) {
      // التحقق من نوع الخطأ
      if (error.code === '23505') {
        return {
          success: false,
          reason: 'duplicate_key',
          message: 'تكرار في البيانات',
          local_id,
          error: error.message
        };
      }
      
      return {
        success: false,
        reason: 'database_error',
        message: 'خطأ في قاعدة البيانات',
        local_id,
        error: error.message
      };
    }

    return {
      success: true,
      data,
      local_id,
      operation: 'INSERT'
    };

  } catch (error) {
    return {
      success: false,
      reason: 'exception',
      message: 'خطأ غير متوقع',
      local_id: operation.local_id,
      error: error.message
    };
  }
};

/**
 * معالجة عملية UPDATE
 */
const handleUpdate = async (storeId, operation) => {
  try {
    const { local_id, table_name, payload } = operation;
    
    // البحث عن السجل بواسطة local_id
    const { data: existingRecord, error: fetchError } = await supabase
      .from(table_name)
      .select('id')
      .eq('store_id', storeId)
      .eq('local_id', local_id)
      .single();

    if (fetchError || !existingRecord) {
      return {
        success: false,
        reason: 'record_not_found',
        message: 'السجل غير موجود للتحديث',
        local_id
      };
    }

    // تحديث السجل
    const updateData = {
      ...payload,
      updated_at: new Date().toISOString()
    };

    const { data, error } = await supabaseAdmin
      .from(table_name)
      .update(updateData)
      .eq('id', existingRecord.id)
      .select()
      .single();

    if (error) {
      return {
        success: false,
        reason: 'database_error',
        message: 'خطأ في تحديث السجل',
        local_id,
        error: error.message
      };
    }

    return {
      success: true,
      data,
      local_id,
      operation: 'UPDATE'
    };

  } catch (error) {
    return {
      success: false,
      reason: 'exception',
      message: 'خطأ غير متوقع',
      local_id: operation.local_id,
      error: error.message
    };
  }
};

/**
 * معالجة عملية DELETE
 */
const handleDelete = async (storeId, operation) => {
  try {
    const { local_id, table_name } = operation;
    
    // البحث عن السجل بواسطة local_id
    const { data: existingRecord, error: fetchError } = await supabase
      .from(table_name)
      .select('id')
      .eq('store_id', storeId)
      .eq('local_id', local_id)
      .single();

    if (fetchError || !existingRecord) {
      return {
        success: false,
        reason: 'record_not_found',
        message: 'السجل غير موجود للحذف',
        local_id
      };
    }

    // حذف السجل
    const { error } = await supabaseAdmin
      .from(table_name)
      .delete()
      .eq('id', existingRecord.id);

    if (error) {
      return {
        success: false,
        reason: 'database_error',
        message: 'خطأ في حذف السجل',
        local_id,
        error: error.message
      };
    }

    return {
      success: true,
      data: { id: existingRecord.id },
      local_id,
      operation: 'DELETE'
    };

  } catch (error) {
    return {
      success: false,
      reason: 'exception',
      message: 'خطأ غير متوقع',
      local_id: operation.local_id,
      error: error.message
    };
  }
};

/**
 * تنفيذ عملية المزامنة
 */
const executeSyncOperation = async (storeId, operation) => {
  const { operation: opType } = operation;

  switch (opType.toUpperCase()) {
    case 'INSERT':
      return await handleInsert(storeId, operation);
    
    case 'UPDATE':
      return await handleUpdate(storeId, operation);
    
    case 'DELETE':
      return await handleDelete(storeId, operation);
    
    default:
      return {
        success: false,
        reason: 'invalid_operation',
        message: 'نوع العملية غير صالح',
        local_id: operation.local_id
      };
  }
};

/**
 * تسجيل التعارض في sync_queue
 */
const logConflict = async (storeId, operation, serverData, reason) => {
  const { data, error } = await supabaseAdmin
    .from('sync_queue')
    .insert({
      id: uuidv4(),
      store_id: storeId,
      local_id: operation.local_id,
      table_name: operation.table_name,
      operation: operation.operation,
      payload: operation.payload,
      server_data: serverData,
      conflict_reason: reason,
      status: 'conflict',
      created_at: new Date().toISOString()
    })
    .select()
    .single();

  return { data, error };
};

/**
 * تحديث حالة sync_queue
 */
const updateSyncQueueStatus = async (queueId, status, result = null) => {
  const updateData = {
    status,
    updated_at: new Date().toISOString()
  };

  if (result) {
    updateData.result = result;
  }

  const { data, error } = await supabaseAdmin
    .from('sync_queue')
    .update(updateData)
    .eq('id', queueId)
    .select()
    .single();

  return { data, error };
};

/**
 * جلب التغييرات منذ تاريخ معين
 */
const getChangesSince = async (storeId, lastSyncAt) => {
  const changes = {};
  const tables = [
    'customers',
    'products',
    'installment_plans',
    'payment_schedule',
    'payments',
    'guarantors'
  ];

  for (const table of tables) {
    let query = supabase
      .from(table)
      .select('*')
      .eq('store_id', storeId);

    if (lastSyncAt) {
      query = query.gte('updated_at', lastSyncAt);
    }

    const { data, error } = await query.order('updated_at', { ascending: true });

    if (!error && data) {
      changes[table] = data;
    }
  }

  return changes;
};

/**
 * حل التعارض
 */
const resolveConflict = async (queueId, resolution) => {
  try {
    // جلب بيانات التعارض
    const { data: conflict, error: fetchError } = await supabase
      .from('sync_queue')
      .select('*')
      .eq('id', queueId)
      .single();

    if (fetchError || !conflict) {
      return {
        success: false,
        message: 'التعارض غير موجود'
      };
    }

    let result;
    if (resolution === 'keep_server') {
      // الاحتفاظ ببيانات الخادم - تحديث الحالة فقط
      result = 'kept_server_data';
    } else if (resolution === 'keep_local') {
      // الاحتفاظ ببيانات المحلية - تنفيذ العملية مرة أخرى
      const operation = {
        local_id: conflict.local_id,
        table_name: conflict.table_name,
        operation: conflict.operation,
        payload: conflict.payload
      };

      const syncResult = await executeSyncOperation(conflict.store_id, operation);
      result = syncResult.success ? 'applied_local_data' : 'failed_to_apply_local';
    }

    // تحديث حالة التعارض
    await updateSyncQueueStatus(queueId, 'resolved', result);

    return {
      success: true,
      message: 'تم حل التعارض بنجاح',
      result
    };

  } catch (error) {
    return {
      success: false,
      message: 'خطأ في حل التعارض',
      error: error.message
    };
  }
};

/**
 * تنظيف sync_queue القديمة
 */
const cleanupOldSyncQueue = async (storeId, daysOld = 30) => {
  const cutoffDate = moment().subtract(daysOld, 'days').toISOString();

  const { error } = await supabaseAdmin
    .from('sync_queue')
    .delete()
    .eq('store_id', storeId)
    .in('status', ['synced', 'resolved'])
    .lt('created_at', cutoffDate);

  return { error };
};

module.exports = {
  executeSyncOperation,
  logConflict,
  updateSyncQueueStatus,
  getChangesSince,
  resolveConflict,
  cleanupOldSyncQueue,
  checkLocalIdExists
};
