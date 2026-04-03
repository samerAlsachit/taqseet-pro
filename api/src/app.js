require('dotenv').config({ path: require('path').resolve(__dirname, '../.env') });
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const { errorHandler, notFoundHandler } = require('./middleware/errorHandler');

const app = express();

// إعدادات الأمان
app.use(helmet());

// CORS
app.use(cors({
  origin: true,
  credentials: true
}));

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 100,
  message: {
    success: false,
    error: 'تجاوزت الحد الأقصى للطلبات، يرجى المحاولة لاحقاً',
    code: 'RATE_LIMIT_EXCEEDED'
  }
});
app.use(limiter);

// Body parser
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Health check
app.get('/health', (req, res) => {
  res.json({
    success: true,
    data: {
      status: 'running',
      timestamp: new Date().toISOString(),
      version: '1.0.0'
    },
    message: 'الخادم يعمل بشكل طبيعي'
  });
});

// Routes (جميع الاستيرادات في مكان واحد)
const telegramRoutes = require('./routes/telegram');
const cashSalesRoutes = require('./routes/cash-sales');
app.use('/api/auth', require('./routes/auth'));
app.use('/api/customers', require('./routes/customers'));
app.use('/api/guarantors', require('./routes/guarantors'));
app.use('/api/products', require('./routes/products'));
app.use('/api/installments', require('./routes/installments'));
app.use('/api/payments', require('./routes/payments'));
app.use('/api/sync', require('./routes/sync'));
app.use('/api/admin', require('./routes/admin'));
app.use('/api/dashboard', require('./routes/dashboard'));
app.use('/api/reports', require('./routes/reports'));
app.use('/api/store', require('./routes/store'));
app.use('/api/plans', require('./routes/plans'));
app.use('/api/cash-sales', cashSalesRoutes);
app.use('/api/telegram', telegramRoutes);

// Error handlers
app.use(notFoundHandler);
app.use(errorHandler);

// تشغيل الخادم
const PORT = process.env.PORT || 3000;

app.listen(PORT, () => {
  console.log(`🚀 خادم مرساة يعمل على المنفذ ${PORT}`);
  console.log(`🌍 البيئة: ${process.env.NODE_ENV || 'development'}`);
  console.log(`📊 الصحة: http://localhost:${PORT}/health`);
});

// تشغيل Cron Job للتنبيهات
require('./cron/expiryNotifications');

// تشغيل Cron Job للنسخ الاحتياطي
require('./cron/backupScheduler');

// تشغيل Cron Job لإشعارات الأقساط المستحقة
require('./cron/dueInstallmentsNotifications');

module.exports = app;
