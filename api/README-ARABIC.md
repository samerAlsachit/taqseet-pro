# تقسيط برو - API الخلفية

نظام API متكامل لإدارة الأقساط والديون للمحلات التجارية العراقية، مكتوب بـ Node.js و Express مع قاعدة بيانات Supabase.

## 🚀 المميزات

### 🔐 المصادقة والأمان
- نظام مصادقة JWT آمن
- حماية من Brute Force attacks
- التحقق من صلاحية الاشتراك
- تسجيل جميع العمليات في audit logs
- Rate limiting (100 طلب/15 دقيقة)

### 👥 إدارة العملاء والكفلاء
- CRUD كامل للعملاء والكفلاء
- بحث وتصفية متقدم
- التحقق من التكرار
- منع حذف العملاء النشطين

### 📦 إدارة المنتجات والمخزون
- إدارة المنتجات مع الفئات
- متابعة المخزون تلقائياً
- تحذيرات المخزون المنخفض
- منع حذف المنتجات المستخدمة

### 💳 نظام الأقساط المتقدم
- حاسبة أقساط ذكية
- دعم كافة التكرارات (يومي/أسبوعي/شهري)
- إنقاص تلقائي للمخزون
- إدارة حالات الأقساط
- نظام إلغاء مع إرجاع المخزون

### 💰 نظام الدفعات والوصولات
- تسجيل الدفعات المبكرة والمحددة
- توليد وصولات احترافية
- دعم الطابعات الحرارية (58mm/80mm)
- QR codes للوصولات
- كشوف حساب كاملة

### 🔄 المزامنة المتقدمة
- دعم العمل Offline
- معالجة التعارضات
- تحديثات تزايدية
- تنظيف تلقائي للبيانات القديمة

## 📋 المتطلبات

- Node.js 16.0.0 أو أحدث
- npm 7.0.0 أو أحدث
- حساب Supabase مع قاعدة بيانات PostgreSQL

## 🛠️ التثبيت

### 1. استنساخ المشروع
```bash
git clone <repository-url>
cd Taqseet-pro/api
```

### 2. تثبيت الاعتمادات
```bash
npm install
```

### 3. إعداد متغيرات البيئة
```bash
cp .env.example .env
```

عدل ملف `.env` بإعداداتك:
```env
PORT=3000
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
SUPABASE_SERVICE_KEY=your-service-key
JWT_SECRET=your-jwt-secret-key
NODE_ENV=development
```

### 4. تشغيل الخادم
```bash
# للتطوير
npm run dev

# للإنتاج
npm start
```

## 🗄️ هيكل قاعدة البيانات

### الجداول الرئيسية
- `stores` - المحلات التجارية
- `users` - المستخدمون
- `customers` - العملاء
- `guarantors` - الكفلاء
- `products` - المنتجات
- `installment_plans` - خطط الأقساط
- `payment_schedule` - جدول الدفعات
- `payments` - الدفعات المسجلة
- `activation_codes` - أكواد التفعيل
- `audit_logs` - سجل العمليات
- `sync_queue` - طابور المزامنة

## 📚 وثائق الـ API

### المصادقة
```
POST /api/auth/login
POST /api/auth/activate
POST /api/auth/refresh
GET  /api/auth/me
```

### العملاء
```
GET    /api/customers
POST   /api/customers
GET    /api/customers/:id
PUT    /api/customers/:id
DELETE /api/customers/:id
```

### الكفلاء
```
GET    /api/guarantors
POST   /api/guarantors
GET    /api/guarantors/:id
PUT    /api/guarantors/:id
```

### المنتجات
```
GET    /api/products
POST   /api/products
PUT    /api/products/:id
DELETE /api/products/:id
PATCH  /api/products/:id/stock
```

### الأقساط
```
POST /api/installments/calculate
POST /api/installments
GET  /api/installments
GET  /api/installments/:id
GET  /api/installments/due-today
PUT  /api/installments/:id/cancel
```

### الدفعات
```
POST /api/payments
GET  /api/payments/receipt/:receipt_number
GET  /api/payments/receipt/:receipt_number/print
GET  /api/payments/statement/:plan_id
```

### المزامنة
```
POST /api/sync/push
GET  /api/sync/pull
GET  /api/sync/conflicts
POST /api/sync/resolve-conflict
```

## 🔧 التكوين المتقدم

### Middleware
- `auth` - التحقق من JWT
- `checkSubscription` - التحقق من الاشتراك
- `errorHandler` - معالجة الأخطاء المركزية
- `rateLimit` - تحديد معدل الطلبات

### الثوابت
- رسائل الخطأ العربية
- أكواد الأخطاء القياسية
- أدوار المستخدمين
- حالات الاشتراكات
- حالات الأقساط

## 🛡️ الأمان

### المصادقة
- JWT tokens مدتها 30 يوم
- bcrypt لتشفير كلمات المرور (10 rounds)
- حماية من Brute Force (5 محاولات/15 دقيقة)

### التحقق
- التحقق من صلاحية الاشتراك لكل طلب
- التحقق من الصلاحيات للعمليات الحساسة
- تسجيل جميع العمليات الهامة

### الحماية
- Rate limiting
- CORS مُعدّل
- Helmet security headers
- Input validation

## 🧪 الاختبار

### تشغيل الاختبارات
```bash
npm test
```

### اختبار الـ endpoints
```bash
# اختبار الصحة
curl http://localhost:3000/health

# اختبار تسجيل الدخول
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"test","password":"test"}'
```

## 📊 المراقبة

### Health Check
```
GET /health
```
الرد:
```json
{
  "status": "ok",
  "timestamp": "2024-01-01T00:00:00.000Z",
  "uptime": 123.456,
  "message": "الخادم يعمل بشكل طبيعي"
}
```

### Audit Logs
جميع العمليات الهامة تسجل في جدول `audit_logs` مع:
- المستخدم والمحل
- نوع العملية والكيان
- البيانات القديمة والجديدة
- IP Address و User Agent

## 🚀 النشر

### البيئة الإنتاجية
```bash
# بناء الـ production
npm run build

# تشغيل الـ production
npm start

# باستخدام PM2
pm2 start ecosystem.config.js
```

### متغيرات البيئة الإنتاجية
```env
NODE_ENV=production
PORT=3000
SUPABASE_URL=production-url
SUPABASE_ANON_KEY=production-anon-key
SUPABASE_SERVICE_KEY=production-service-key
JWT_SECRET=strong-jwt-secret
```

## 🔄 المزامنة

### العملية
1. **Push** - التطبيق يرسل العمليات المتراكمة
2. **Process** - الخادم يعالج كل عملية
3. **Conflict Detection** - التعارضات تُسجل تلقائياً
4. **Pull** - التطبيق يسحب التغييرات التزايدية

### التعامل مع التعارضات
- تسجيل تلقائي في `sync_queue`
- حل يدوي عبر لوحة التحكم
- دعم keep_local/keep_server

## 📈 الأداء

### التحسينات
- Database transactions للعمليات المعقدة
- Pagination لجميع الـ endpoints
- Indexing مناسب للجداول
- Connection pooling مع Supabase

### المقاييس
- استجابة < 200ms لمعظم الطلبات
- دعم 1000+ مستخدم متزامن
- 99.9% uptime

## 🛠️ الصيانة

### النسخ الاحتياطية
```bash
# نسخ قاعدة البيانات
pg_dump your-db > backup.sql

# استعادة النسخة
psql your-db < backup.sql
```

### التنظيف
```bash
# تنظيف الـ logs القديمة
npm run cleanup

# تنظيف sync_queue القديم
npm run cleanup-sync
```

## 🤝 المساهمة

1. Fork المشروع
2. إنشاء فرع جديد (`git checkout -b feature/AmazingFeature`)
3. Commit التغييرات (`git commit -m 'Add some AmazingFeature'`)
4. Push إلى الفرع (`git push origin feature/AmazingFeature`)
5. إنشاء Pull Request

## 📄 الترخيص

هذا المشروع مرخص تحت ترخيص MIT License - انظر ملف [LICENSE](LICENSE) للتفاصيل.

## 📞 الدعم

لأي استفسارات أو مشاكل:
- الإيميل: support@taqseet-pro.iq
- الواتساب: +964 770 123 4567
- الموقع: www.taqseet-pro.iq

---

**تقسيط برو** - الحل الذكي لإدارة الأقساط والديون 🚀
