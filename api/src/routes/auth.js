const express = require('express');
const router = express.Router();
const { login, activate, refreshToken, getMe } = require('../controllers/authController');
const { authenticateToken } = require('../middleware/auth');

/**
 * @route   POST /api/auth/login
 * @desc    تسجيل الدخول
 * @access  Public
 */
router.post('/login', login);

/**
 * @route   POST /api/auth/activate
 * @desc    تفعيل الحساب باستخدام كود التفعيل
 * @access  Public
 */
router.post('/activate', activate);

/**
 * @route   POST /api/auth/refresh
 * @desc    تجديد التوكن
 * @access  Public
 */
router.post('/refresh', refreshToken);

/**
 * @route   GET /api/auth/me
 * @desc    جلب بيانات المستخدم الحالي
 * @access  Private
 */
router.get('/me', authenticateToken, getMe);

module.exports = router;
