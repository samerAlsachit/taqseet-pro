const express = require('express');
const router = express.Router();
const { authenticateToken } = require('../middleware/auth');
const checkSubscription = require('../middleware/checkSubscription');
const {
  pushOperations,
  pullChanges,
  getConflicts,
  resolveConflictHandler,
  getSyncStatus,
  cleanupSyncQueue
} = require('../controllers/syncController');

/**
 * @route   POST /api/sync/push
 * @desc    دفع العمليات المتراكمة من التطبيق المحلي
 * @access  Private
 */
router.post('/push', [authenticateToken, checkSubscription], pushOperations);

/**
 * @route   GET /api/sync/pull
 * @desc    سحب التغييرات من الخادم
 * @access  Private
 */
router.get('/pull', [authenticateToken, checkSubscription], pullChanges);

/**
 * @route   GET /api/sync/conflicts/:store_id
 * @desc    جلب التعارضات التي تحتاج حل يدوي
 * @access  Private
 */
router.get('/conflicts', [authenticateToken, checkSubscription], getConflicts);

/**
 * @route   POST /api/sync/resolve-conflict
 * @desc    حل التعارض
 * @access  Private
 */
router.post('/resolve-conflict', [authenticateToken, checkSubscription], resolveConflictHandler);

/**
 * @route   GET /api/sync/status
 * @desc    جلب حالة المزامنة
 * @access  Private
 */
router.get('/status', [authenticateToken, checkSubscription], getSyncStatus);

/**
 * @route   DELETE /api/sync/cleanup
 * @desc    تنظيف sync_queue يدوياً
 * @access  Private
 */
router.delete('/cleanup', [authenticateToken, checkSubscription], cleanupSyncQueue);

module.exports = router;
