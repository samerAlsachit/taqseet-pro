# لوحة تحكم تقسيط برو - Admin Dashboard

لوحة تحكم متقدمة لإدارة نظام تقسيط برو، مكتوبة بـ Next.js 14 و TypeScript مع واجهة عربية احترافية.

## 🚀 المميزات

### 📊 لوحة التحكم الرئيسية
- إحصائيات فورية للمحلات النشطة
- متابعة الإيرادات الشهرية
- نظام تنبيهات للاشتراكات المنتهية
- رسوم بيانية تفاعلية لنمو الاشتراكات

### 🏪 إدارة المحلات
- عرض جميع المحلات مع تفاصيل كاملة
- البحث والتصفية المتقدمة
- تعطيل/تفعيل المحلات
- تمديد الاشتراكات يدوياً
- عرض إحصائيات كل محل

### 🔑 إدارة أكواد التفعيل
- توليد أكواد تفعيل مجمعة
- اختيار الخطة والكمية
- متابعة حالة الأكواد
- نسخ الأكواد بضغطة واحدة
- تصدير الأكواد بصيغة CSV

### 📈 إدارة الاشتراكات
- عرض جميع الاشتراكات النشطة والمنتهية
- إرسال رسائل تجديد تلقائية
- متابعة تجديدات الاشتراكات
- تقارير الإيرادات

## 📋 المتطلبات

- Node.js 18.0.0 أو أحدث
- npm 8.0.0 أو أحدث
- متصفح حديث يدعم TypeScript و ES6+

## 🛠️ التثبيت

### 1. استنساخ المشروع
```bash
git clone <repository-url>
cd Taqseet-pro/admin
```

### 2. تثبيت الاعتمادات
```bash
npm install
```

### 3. إعداد متغيرات البيئة
```bash
cp env.example .env.local
```

عدل ملف `.env.local`:
```env
NEXT_PUBLIC_API_URL=http://localhost:3000
NEXT_PUBLIC_APP_NAME=لوحة تحكم تقسيط برو
```

### 4. تشغيل المشروع
```bash
# للتطوير
npm run dev

# للإنتاج
npm run build
npm start
```

## 🏗️ هيكل المشروع

```
admin/
├── src/
│   ├── app/                    # App Router pages
│   │   ├── (app)/            # Grouped routes
│   │   │   ├── dashboard/     # Dashboard
│   │   │   ├── stores/        # Stores management
│   │   │   ├── activation-codes/ # Activation codes
│   │   │   └── subscriptions/ # Subscriptions
│   │   └── login/           # Login page
│   ├── components/             # Reusable components
│   │   ├── ui/              # shadcn/ui components
│   │   └── common/          # Custom components
│   ├── lib/                  # Utilities and helpers
│   │   ├── api.ts          # API client
│   │   ├── utils.ts         # Helper functions
│   │   └── errorHandler.ts  # Error handling
│   └── types/                # TypeScript definitions
├── public/                  # Static assets
├── env.example              # Environment variables template
└── README.md
```

## 📚 الصفحات والمكونات

### 🔐 تسجيل الدخول (`/login`)
- نموذج تسجيل دخول بسيط
- دعم super_admin فقط
- حفظ JWT في httpOnly cookies
- معالجة الأخطاء بالعربية

### 📊 لوحة التحكم (`/dashboard`)
- بطاقات إحصائيات رئيسية:
  - إجمالي المحلات النشطة
  - إجمالي الإيرادات الشهرية
  - عدد المشتركين الجدد هذا الشهر
  - المحلات التي اشتراكها ينتهي خلال 7 أيام
- رسم بياني لنمو الاشتراكات آخر 12 شهر

### 🏪 إدارة المحلات (`/stores`)
- جدول عرض جميع المحلات مع:
  - الاسم، المالك، الهاتف
  - نوع الاشتراك، تاريخ الانتهاء، الحالة
- بحث وفلترة متقدمة
- أزرار الإجراءات:
  - عرض تفاصيل المحل
  - تعطيل/تفعيل المحل
  - تمديد الاشتراك يدوياً

### 📄 تفاصيل المحل (`/stores/:id`)
- عرض كافة بيانات المحل
- إحصائيات المحل:
  - عدد الزبائن
  - الأقساط النشطة
  - إجمالي المبالغ
- سجل النشاطات

### 🔑 أكواد التفعيل (`/activation-codes`)
- توليد أكواد جديدة:
  - اختيار الخطة (شهري/سنوي)
  - تحديد الكمية
  - تحديد تاريخ الصلاحية
- قائمة الأكواد مع الحالة:
  - مستخدم / غير مستخدم / منتهي الصلاحية
- نسخ الكود بضغطة
- تصدير CSV

### 📈 الاشتراكات (`/subscriptions`)
- عرض جميع الاشتراكات
- فلترة حسب الحالة (نشط/منتهي)
- إرسال رسائل التجديد:
  - رسائل جاهزة
  - إرسال جماعي/فردي
  - سجل الإرسال

## 🎨 التصميم والواجهة

### 🌍 دعم RTL
- اتجاه النصوص من اليمين لليسار بالكامل
- تصميم متجاوب مع اللغة العربية
- خطوط عربية مناسبة

### 🎨 shadcn/ui
- مكونات حديثة وجميلة
- دعم الوضع الداكن/الفاتح
- تصميم متجاوب
- سهولة تخصيص الألوان

### 📱 Responsive Design
- متوافق مع جميع أحجام الشاشات
- تجربة مستخدم ممتازة على الموبايل
- تصميم متكيف مع التابلت

## 🔧 التكوين

### متغيرات البيئة
```env
NEXT_PUBLIC_API_URL=http://localhost:3000    # رابط API الخلفية
NEXT_PUBLIC_APP_NAME=لوحة تحكم تقسيط برو  # اسم التطبيق
```

### إعدادات إضافية
- يمكن تخصيص الألوان عبر CSS Variables
- دعم الثيمات المتعددة
- إعدادات الطباعة

## 🛡️ الأمان

### المصادقة
- JWT tokens آمنة
- httpOnly cookies
- حماية من CSRF
- انتهاء صلاحية تلقائي

### الصلاحيات
- تحقق من صلاحيات super_admin
- حماية المسارات الحساسة
- تسجيل جميع العمليات

## 📊 الرسوم البيانية

### Recharts Integration
- رسوم بيانية تفاعلية
- دعم اللغة العربية
- تصدير الصور
- رسوم بيانية متعددة الأنواع

### أنواع الرسوم البيانية
- Line charts للنمو
- Bar charts للمقارنات
- Pie charts للتوزيع
- Area charts للاتجاهات

## 🔄 التكامل مع API

### API Client
- عميل API مخصص
- معالجة الأخطاء المركزية
- إعادة المحاولة التلقائية
- caching للبيانات

### الـ endpoints المستخدمة
- `/api/auth/login` - تسجيل الدخول
- `/api/stores` - إدارة المحلات
- `/api/activation-codes` - أكواد التفعيل
- `/api/subscriptions` - الاشتراكات
- `/api/reports` - التقارير

## 🧪 الاختبار

### تشغيل الاختبارات
```bash
npm test
```

### اختبار المكونات
```bash
npm run test:components
```

### اختبار الـ API integration
```bash
npm run test:api
```

## 🚀 النشر

### بناء المشروع
```bash
# بناء للإنتاج
npm run build

# فحص البناء
npm run build:analyze
```

### النشر على Vercel
```bash
# تثبيت Vercel CLI
npm i -g vercel

# النشر
vercel --prod
```

### النشر على Docker
```bash
# بناء الصورة
docker build -t taqseet-admin .

# تشغيل الحاوية
docker run -p 3000:3000 taqseet-admin
```

## 📈 الأداء

### التحسينات
- Code splitting تلقائي
- Lazy loading للصفحات
- Optimized images
- Service Worker للـ caching

### المقاييس
- First Contentful Paint < 1.5s
- Largest Contentful Paint < 2.5s
- Cumulative Layout Shift < 0.1
- 95+ Performance Score

## 🛠️ الصيانة

### تحديثات
```bash
# تحديث الاعتمادات
npm update

# تحديث الأمنية
npm audit fix
```

### المراقبة
- Sentry integration للأخطاء
- Analytics لاستخدام المستخدمين
- Performance monitoring

## 🤝 المساهمة

### قواعد المساهمة
1. Fork المشروع
2. إنشاء فرع جديد
3. تطوير الميزة أو إصلاح الخلل
4. كتابة الاختبارات
5. إنشاء Pull Request

### Code Style
- استخدام ESLint و Prettier
- اتبع قواعد TypeScript
- كتابة تعليقات بالعربية
- اختبار قبل الـ commit

## 📄 الترخيص

هذا المشروع مرخص تحت ترخيص MIT License - انظر ملف [LICENSE](LICENSE) للتفاصيل.

## 📞 الدعم الفني

لأي استفسارات أو مشاكل تقنية:
- الإيميل: admin@taqseet-pro.iq
- الواتساب: +964 770 123 4568
- التوثيق: docs.taqseet-pro.iq

---

**لوحة تحكم تقسيط برو** - إدارة احترافية لنظام الأقساط 🚀
