const express = require('express');
const router = express.Router();
const { authenticateToken } = require('../middleware/auth');
const checkSubscription = require('../middleware/checkSubscription');
const {
  getProducts,
  createProduct,
  updateProduct,
  deleteProduct,
  updateStock
} = require('../controllers/productsController');

/**
 * @route   GET /api/products
 * @desc    جلب قائمة المنتجات
 * @access  Private
 */
router.get('/', [authenticateToken, checkSubscription], getProducts);

/**
 * @route   POST /api/products
 * @desc    إنشاء منتج جديد
 * @access  Private
 */
router.post('/', [authenticateToken, checkSubscription], createProduct);

/**
 * @route   PUT /api/products/:id
 * @desc    تحديث بيانات منتج
 * @access  Private
 */
router.put('/:id', [authenticateToken, checkSubscription], updateProduct);

/**
 * @route   DELETE /api/products/:id
 * @desc    حذف منتج
 * @access  Private
 */
router.delete('/:id', [authenticateToken, checkSubscription], deleteProduct);

/**
 * @route   PATCH /api/products/:id/stock
 * @desc    تعديل المخزون يدوياً
 * @access  Private
 */
router.patch('/:id/stock', [authenticateToken, checkSubscription], updateStock);

module.exports = router;
