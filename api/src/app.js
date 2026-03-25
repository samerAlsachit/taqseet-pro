require('dotenv').config();
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const { errorHandler, notFoundHandler } = require('./middleware/errorHandler');

// إنشاء تطبيق Express
const app = express();

// إعدادات الأمان
app.use(helmet());

// تفعيل CORS لجميع الـ origins مبدئياً
app.use(cors({
  origin: true, // السماح بجميع الـ origins
  credentials: true
}));

// تحديد حد للطلبات (100 طلب كل 15 دقيقة)
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 دقيقة
  max: 100, // حد أقصى 100 طلب
  message: {
    success: false,
    error: 'تجاوزت الحد الأقصى للطلبات، يرجى المحاولة لاحقاً',
    code: 'RATE_LIMIT_EXCEEDED'
  },
  standardHeaders: true,
  legacyHeaders: false
});

app.use(limiter);

// تحليل JSON body
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// مسار الصحة للتحقق من عمل الخادم
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

// المسارات الرئيسية
app.use('/api/auth', require('./routes/auth'));
app.use('/api/customers', require('./routes/customers'));
app.use('/api/guarantors', require('./routes/guarantors'));
app.use('/api/products', require('./routes/products'));
app.use('/api/installments', require('./routes/installments'));
app.use('/api/payments', require('./routes/payments'));
app.use('/api/sync', require('./routes/sync'));
app.use('/api/admin', require('./routes/admin'));
// app.use('/api/stores', require('./routes/stores'));

// معالجة المسارات غير الموجودة
app.use(notFoundHandler);

// معالجة الأخطاء المركزية
app.use(errorHandler);

// تشغيل الخادم
const PORT = process.env.PORT || 3000;

app.listen(PORT, () => {
  console.log(`🚀 خادم تقسيط برو يعمل على المنفذ ${PORT}`);
  console.log(`🌍 البيئة: ${process.env.NODE_ENV || 'development'}`);
  console.log(`📊 الصحة: http://localhost:${PORT}/health`);
});

module.exports = app;
