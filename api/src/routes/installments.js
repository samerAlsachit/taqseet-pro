const express = require('express');
const router = express.Router();
const { authenticateToken } = require('../middleware/auth');
const checkSubscription = require('../middleware/checkSubscription');
const {
  calculateInstallmentSchedule,
  createInstallmentPlan,
  getInstallmentPlans,
  getInstallmentPlan,
  getDueInstallments,
  cancelInstallmentPlan
} = require('../controllers/installmentsController');

/**
 * @route   POST /api/installments/calculate
 * @desc    حساب جدول الأقساط (للمعاينة فقط)
 * @access  Private
 */
router.post('/calculate', [authenticateToken, checkSubscription], calculateInstallmentSchedule);

/**
 * @route   POST /api/installments
 * @desc    إنشاء خطة قسط جديدة
 * @access  Private
 */
router.post('/', [authenticateToken, checkSubscription], createInstallmentPlan);

/**
 * @route   GET /api/installments
 * @desc    جلب قائمة خطط الأقساط
 * @access  Private
 */
router.get('/', [authenticateToken, checkSubscription], getInstallmentPlans);

/**
 * @route   GET /api/installments/due-today
 * @desc    جلب الأقساط المستحقة (المتأخرة + اليوم + القادمة خلال 7 أيام)
 * @access  Private
 */
router.get('/due-today', [authenticateToken, checkSubscription], getDueInstallments);

/**
 * @route   GET /api/installments/:id
 * @desc    جلب تفاصيل خطة الأقساط
 * @access  Private
 */
router.get('/:id', [authenticateToken, checkSubscription], getInstallmentPlan);

/**
 * @route   PUT /api/installments/:id/cancel
 * @desc    إلغاء خطة الأقساط
 * @access  Private
 */
router.put('/:id/cancel', [authenticateToken, checkSubscription], cancelInstallmentPlan);

module.exports = router;
