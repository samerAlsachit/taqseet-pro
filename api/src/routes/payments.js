const express = require('express');
const router = express.Router();
const { authenticateToken } = require('../middleware/auth');
const checkSubscription = require('../middleware/checkSubscription');
const {
  createPayment,
  getReceipt,
  printReceipt,
  getStatement
} = require('../controllers/paymentsController');

/**
 * @route   POST /api/payments
 * @desc    إنشاء دفعة جديدة
 * @access  Private
 */
router.post('/', [authenticateToken, checkSubscription], createPayment);

/**
 * @route   GET /api/payments/receipt/:receipt_number
 * @desc    جلب بيانات الوصل
 * @access  Private
 */
router.get('/receipt/:receipt_number', [authenticateToken, checkSubscription], getReceipt);

/**
 * @route   GET /api/payments/receipt/:receipt_number/print
 * @desc    طباعة الوصل (HTML)
 * @access  Private
 */
router.get('/receipt/:receipt_number/print', [authenticateToken, checkSubscription], printReceipt);

/**
 * @route   GET /api/payments/statement/:plan_id
 * @desc    جلب كشف حساب العميل
 * @access  Private
 */
router.get('/statement/:plan_id', [authenticateToken, checkSubscription], getStatement);

module.exports = router;
