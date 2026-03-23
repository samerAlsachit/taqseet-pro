const { supabase, supabaseAdmin } = require('../config/supabase');
const { ERROR_CODES, ERROR_MESSAGES } = require('../config/constants');
const { v4: uuidv4 } = require('uuid');
const {
  executeSyncOperation,
  logConflict,
  updateSyncQueueStatus,
  getChangesSince,
  resolveConflict,
  cleanupOldSyncQueue
} = require('../services/syncService');
const moment = require('moment');

/**
 * دفع العمليات المتراكمة من التطبيق المحلي
 */
const pushOperations = async (req, res) => {
  try {
    const storeId = req.user.store_id;
    const { operations } = req.body;

    if (!Array.isArray(operations) || operations.length === 0) {
      return res.status(400).json({
        success: false,
        error: 'قائمة العمليات مطلوبة',
        code: ERROR_CODES.VALIDATION_ERROR
      });
    }

    const results = {
      synced: [],
      conflicts: [],
      failed: []
    };

    // معالجة كل عملية
    for (const operation of operations) {
      try {
        // التحقق من صحة العملية
        if (!operation.local_id || !operation.table_name || !operation.operation) {
          results.failed.push({
            local_id: operation.local_id || 'unknown',
            reason: 'invalid_operation',
            message: 'بيانات العملية غير صالحة'
          });
          continue;
        }

        // تنفيذ العملية
        const result = await executeSyncOperation(storeId, operation);

        if (result.success) {
          results.synced.push(result);
        } else {
          // التحقق من نوع الخطأ
          if (result.reason === 'duplicate_key' || result.reason === 'local_id_exists') {
            // تسجيل كتعارض
            const conflictData = {
              local_id: operation.local_id,
              table_name: operation.table_name,
              operation: operation.operation,
              payload: operation.payload,
              conflict_reason: result.reason,
              status: 'conflict'
            };

            // جلب بيانات الخادم للتعارض
            const { data: serverData } = await supabase
              .from(operation.table_name)
              .select('*')
              .eq('store_id', storeId)
              .eq('local_id', operation.local_id)
              .single();

            await logConflict(storeId, operation, serverData, result.reason);
            
            results.conflicts.push({
              ...conflictData,
              server_data: serverData,
              message: result.message
            });
          } else {
            results.failed.push(result);
          }
        }

      } catch (error) {
        results.failed.push({
          local_id: operation.local_id || 'unknown',
          reason: 'exception',
          message: 'خطأ غير متوقع',
          error: error.message
        });
      }
    }

    // تنظيف sync_queue القديمة
    await cleanupOldSyncQueue(storeId);

    res.json({
      success: true,
      data: results,
      message: 'تمت معالجة العمليات بنجاح'
    });

  } catch (error) {
    console.error('خطأ في دفع العمليات:', error);
    res.status(500).json({
      success: false,
      error: ERROR_MESSAGES[ERROR_CODES.INTERNAL_ERROR],
      code: ERROR_CODES.INTERNAL_ERROR
    });
  }
};

/**
 * سحب التغييرات من الخادم
 */
const pullChanges = async (req, res) => {
  try {
    const storeId = req.user.store_id;
    const { last_sync_at } = req.query;

    // جلب التغييرات منذ آخر مزامنة
    const changes = await getChangesSince(storeId, last_sync_at);

    res.json({
      success: true,
      data: {
        ...changes,
        server_time: new Date().toISOString()
      },
      message: 'تم جلب التغييرات بنجاح'
    });

  } catch (error) {
    console.error('خطأ في سحب التغييرات:', error);
    res.status(500).json({
      success: false,
      error: ERROR_MESSAGES[ERROR_CODES.INTERNAL_ERROR],
      code: ERROR_CODES.INTERNAL_ERROR
    });
  }
};

/**
 * جلب التعارضات التي تحتاج حل يدوي
 */
const getConflicts = async (req, res) => {
  try {
    const storeId = req.user.store_id;

    const { data: conflicts, error } = await supabase
      .from('sync_queue')
      .select('*')
      .eq('store_id', storeId)
      .eq('status', 'conflict')
      .order('created_at', { ascending: false });

    if (error) {
      console.error('خطأ في جلب التعارضات:', error);
      return res.status(500).json({
        success: false,
        error: ERROR_MESSAGES[ERROR_CODES.INTERNAL_ERROR],
        code: ERROR_CODES.INTERNAL_ERROR
      });
    }

    res.json({
      success: true,
      data: conflicts || [],
      message: 'تم جلب التعارضات بنجاح'
    });

  } catch (error) {
    console.error('خطأ في جلب التعارضات:', error);
    res.status(500).json({
      success: false,
      error: ERROR_MESSAGES[ERROR_CODES.INTERNAL_ERROR],
      code: ERROR_CODES.INTERNAL_ERROR
    });
  }
};

/**
 * حل التعارض
 */
const resolveConflictHandler = async (req, res) => {
  try {
    const { sync_queue_id, resolution } = req.body;

    if (!sync_queue_id || !resolution) {
      return res.status(400).json({
        success: false,
        error: 'معرّف التعارض ونوع الحل مطلوبان',
        code: ERROR_CODES.VALIDATION_ERROR
      });
    }

    if (!['keep_local', 'keep_server'].includes(resolution)) {
      return res.status(400).json({
        success: false,
        error: 'نوع الحل غير صالح',
        code: ERROR_CODES.VALIDATION_ERROR
      });
    }

    const result = await resolveConflict(sync_queue_id, resolution);

    if (result.success) {
      res.json({
        success: true,
        data: result,
        message: 'تم حل التعارض بنجاح'
      });
    } else {
      res.status(400).json({
        success: false,
        error: result.message,
        code: ERROR_CODES.VALIDATION_ERROR
      });
    }

  } catch (error) {
    console.error('خطأ في حل التعارض:', error);
    res.status(500).json({
      success: false,
      error: ERROR_MESSAGES[ERROR_CODES.INTERNAL_ERROR],
      code: ERROR_CODES.INTERNAL_ERROR
    });
  }
};

/**
 * جلب حالة المزامنة
 */
const getSyncStatus = async (req, res) => {
  try {
    const storeId = req.user.store_id;

    // جلب إحصائيات المزامنة
    const { data: stats, error } = await supabase
      .from('sync_queue')
      .select('status')
      .eq('store_id', storeId);

    if (error) {
      console.error('خطأ في جلب إحصائيات المزامنة:', error);
      return res.status(500).json({
        success: false,
        error: ERROR_MESSAGES[ERROR_CODES.INTERNAL_ERROR],
        code: ERROR_CODES.INTERNAL_ERROR
      });
    }

    const statusCounts = (stats || []).reduce((acc, item) => {
      acc[item.status] = (acc[item.status] || 0) + 1;
      return acc;
    }, {});

    // جلب آخر مزامنة ناجحة
    const { data: lastSync, error: lastSyncError } = await supabase
      .from('sync_queue')
      .select('created_at')
      .eq('store_id', storeId)
      .eq('status', 'synced')
      .order('created_at', { ascending: false })
      .limit(1)
      .single();

    res.json({
      success: true,
      data: {
        status_counts: statusCounts,
        last_successful_sync: lastSync ? lastSync.created_at : null,
        server_time: new Date().toISOString()
      },
      message: 'تم جلب حالة المزامنة بنجاح'
    });

  } catch (error) {
    console.error('خطأ في جلب حالة المزامنة:', error);
    res.status(500).json({
      success: false,
      error: ERROR_MESSAGES[ERROR_CODES.INTERNAL_ERROR],
      code: ERROR_CODES.INTERNAL_ERROR
    });
  }
};

/**
 * تنظيف sync_queue يدوياً
 */
const cleanupSyncQueue = async (req, res) => {
  try {
    const storeId = req.user.store_id;
    const { days_old = 30 } = req.query;

    if (!req.user.can_delete) {
      return res.status(403).json({
        success: false,
        error: ERROR_MESSAGES[ERROR_CODES.INSUFFICIENT_PERMISSIONS],
        code: ERROR_CODES.INSUFFICIENT_PERMISSIONS
      });
    }

    const { error } = await cleanupOldSyncQueue(storeId, parseInt(days_old));

    if (error) {
      console.error('خطأ في تنظيف قائمة المزامنة:', error);
      return res.status(500).json({
        success: false,
        error: ERROR_MESSAGES[ERROR_CODES.INTERNAL_ERROR],
        code: ERROR_CODES.INTERNAL_ERROR
      });
    }

    res.json({
      success: true,
      data: null,
      message: `تم تنظيف قائمة المزامنة القديمة (${days_old} يوم) بنجاح`
    });

  } catch (error) {
    console.error('خطأ في تنظيف قائمة المزامنة:', error);
    res.status(500).json({
      success: false,
      error: ERROR_MESSAGES[ERROR_CODES.INTERNAL_ERROR],
      code: ERROR_CODES.INTERNAL_ERROR
    });
  }
};

module.exports = {
  pushOperations,
  pullChanges,
  getConflicts,
  resolveConflictHandler,
  getSyncStatus,
  cleanupSyncQueue
};
