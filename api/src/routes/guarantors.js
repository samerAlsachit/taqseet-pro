const express = require('express');
const router = express.Router();
const { authenticateToken } = require('../middleware/auth');
const checkSubscription = require('../middleware/checkSubscription');
const {
  createGuarantor,
  getGuarantor,
  updateGuarantor,
  getGuarantors
} = require('../controllers/guarantorsController');

/**
 * @route   GET /api/guarantors
 * @desc    جلب قائمة الكفلاء
 * @access  Private
 */
router.get('/', [authenticateToken, checkSubscription], getGuarantors);

/**
 * @route   POST /api/guarantors
 * @desc    إنشاء كفيل جديد
 * @access  Private
 */
router.post('/', [authenticateToken, checkSubscription], createGuarantor);

/**
 * @route   GET /api/guarantors/:id
 * @desc    جلب بيانات كفيل محدد
 * @access  Private
 */
router.get('/:id', [authenticateToken, checkSubscription], getGuarantor);

/**
 * @route   PUT /api/guarantors/:id
 * @desc    تحديث بيانات كفيل
 * @access  Private
 */
router.put('/:id', [authenticateToken, checkSubscription], updateGuarantor);

module.exports = router;
