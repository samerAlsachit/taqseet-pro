const express = require('express');
const router = express.Router();
const { authenticateToken } = require('../middleware/auth');
const checkSubscription = require('../middleware/checkSubscription');
const {
  getCustomers,
  createCustomer,
  getCustomer,
  updateCustomer,
  deleteCustomer
} = require('../controllers/customersController');

/**
 * @route   GET /api/customers
 * @desc    جلب قائمة العملاء
 * @access  Private
 */
router.get('/', [authenticateToken, checkSubscription], getCustomers);

/**
 * @route   POST /api/customers
 * @desc    إنشاء عميل جديد
 * @access  Private
 */
router.post('/', [authenticateToken, checkSubscription], createCustomer);

/**
 * @route   GET /api/customers/:id
 * @desc    جلب بيانات عميل محدد
 * @access  Private
 */
router.get('/:id', [authenticateToken, checkSubscription], getCustomer);

/**
 * @route   PUT /api/customers/:id
 * @desc    تحديث بيانات عميل
 * @access  Private
 */
router.put('/:id', [authenticateToken, checkSubscription], updateCustomer);

/**
 * @route   DELETE /api/customers/:id
 * @desc    حذف عميل
 * @access  Private
 */
router.delete('/:id', [authenticateToken, checkSubscription], deleteCustomer);

module.exports = router;
