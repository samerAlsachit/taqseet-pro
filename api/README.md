# تقسيط برو - API

نظام SaaS متكامل لإدارة الأقساط والديون للمحلات التجارية العراقية.

## 🚀 المميزات

- إدارة المحلات التجارية
- إدارة العملاء والديون
- نظام الأقساط المرنة
- متابعة الدفعات
- نظام اشتراكات متقدم
- واجهة API عربية بالكامل

## 📋 المتطلبات

- Node.js 16 أو أحدث
- npm أو yarn
- حساب Supabase

## 🛠️ التثبيت

1. نسخ المشروع:
```bash
git clone <repository-url>
cd taqseet-pro-api
```

2. تثبيت الاعتمادات:
```bash
npm install
```

3. إعداد المتغيرات البيئية:
```bash
cp .env.example .env
```

4. تعديل ملف `.env` بإعدادات Supabase والمتغيرات الأخرى:
```env
PORT=3000
SUPABASE_URL=your_supabase_url
SUPABASE_ANON_KEY=your_supabase_anon_key
SUPABASE_SERVICE_KEY=your_supabase_service_key
JWT_SECRET=your_jwt_secret_key
NODE_ENV=development
```

## 🏗️ هيكل المشروع

```
api/
├── src/
│   ├── config/
│   │   ├── supabase.js       ← اتصال Supabase
│   │   └── constants.js      ← ثوابت المشروع
│   ├── middleware/
│   │   ├── auth.js           ← التحقق من JWT
│   │   ├── checkSubscription.js ← التحقق من صلاحية الاشتراك
│   │   └── errorHandler.js   ← معالجة الأخطاء
│   ├── routes/               ← مسارات API
│   ├── controllers/          ← منطق الأعمال
│   ├── services/             ← الخدمات
│   └── app.js                ← إعدادات Express
├── .env.example
├── package.json
└── README.md
```

## 🔧 تشغيل المشروع

### في بيئة التطوير:
```bash
npm run dev
```

### في بيئة الإنتاج:
```bash
npm start
```

## 📊 نقاط النهاية

### الصحة
- `GET /health` - التحقق من حالة الخادم

### المصادقة (سيتم إضافتها)
- `POST /api/auth/login` - تسجيل الدخول
- `POST /api/auth/register` - تسجيل جديد
- `POST /api/auth/refresh` - تجديد التوكن

### المحلات (سيتم إضافتها)
- `GET /api/stores` - جلب المحلات
- `POST /api/stores` - إنشاء محل جديد
- `PUT /api/stores/:id` - تحديث بيانات المحل
- `DELETE /api/stores/:id` - حذف محل

## 🔐 المصادقة

يستخدم النظام توكنات JWT للمصادقة. يجب إضافة التوكن في header الطلب:

```
Authorization: Bearer <your_jwt_token>
```

## 📝 تنسيق الردود

جميع الردود تتبع التنسيق الموحد:

### نجاح:
```json
{
  "success": true,
  "data": {...},
  "message": "رسالة النجاح"
}
```

### خطأ:
```json
{
  "success": false,
  "error": "رسالة الخطأ",
  "code": "ERROR_CODE"
}
```

## 🛡️ الحماية

- Rate limiting (100 طلب كل 15 دقيقة)
- CORS مفعّل
- Helmet للأمان
- التحقق من صلاحية الاشتراك
- التحقق من صلاحيات المستخدم

## 📞 الدعم

لأي استفسارات أو مشاكل، يرجى التواصل مع فريق تقسيط برو.

## 📄 الرخصة

MIT License
