# 🧠 PROJECT MEMORY
> آخر تحديث: 2026-05-11 01:30 (بغداد)
> يجب تحديث هذا الملف تلقائياً بعد كل تعديل أو إضافة

---

## 📌 هوية المشروع
- **الاسم:** تقسيط برو (Marsa / مرساة)
- **النوع:** Full-stack SaaS
- **الغرض:** نظام متكامل لإدارة الأقساط والديون للمحلات التجارية العراقية — يشمل إدارة العملاء، الأقساط المرنة (يومي/أسبوعي/شهري)، المدفوعات والإيصالات، المخزون، المزامنة اللامركزية، مع تطبيق موبايل يعمل Offline-first ولوحة تحكم للمشرفين.
- **الحالة الراهنة:** تطوير (Development)

---

## 🛠️ التقنيات المستخدمة

### Frontend
- **Web App:** Next.js 14 (App Router), React 18, TypeScript, Tailwind CSS 4, Radix UI, Lucide Icons, jspdf, xlsx, sweetalert2
- **Admin Panel:** Next.js 15 (App Router), React 19.2, TypeScript, Tailwind CSS 4, shadcn/ui (Radix-Nova style), Recharts, date-fns, lucide-react
- **Mobile App 1 (marsa):** Flutter, Dart 3.11+, Provider, Dio, Supabase Flutter, Hive, google_fonts, pdf/printing, url_launcher, local_auth
- **Mobile App 2 (marsa_mobile):** Flutter, Dart 3.0+, flutter_bloc, Provider, GetIt, Injectable, Dio, Retrofit, Hive, sqflite, Supabase Flutter, local_auth, flutter_local_notifications, mobile_scanner, qr_flutter, pdf/printing
- **Mobile App 3 (marsa_app — AppNew):** Flutter 3.41.4, Dart 3.11.1, flutter_bloc, Provider, GetIt, Hive, sqflite, Supabase Flutter, Dio, local_auth, printing, flutter_image_compress, image_picker, intl, connectivity_plus, uuid, path_provider, cached_network_image

### Backend
- **Runtime:** Node.js 16+
- **Framework:** Express.js 4.18
- **المصادقة:** JWT (jsonwebtoken) + bcryptjs
- **التحقق:** Joi validation
- **الأمان:** Helmet, CORS, express-rate-limit (100 req/15min)
- **المهام المجدولة:** node-cron (توقيت بغداد Asia/Baghdad)
- **الخدمات:** Supabase JS SDK, Google APIs, Resend (إيميلات), QRCode, UUID, moment.js, axios
- **التطوير:** nodemon

### قاعدة البيانات
- **Supabase (PostgreSQL)** — REST API + Admin Client
- **التخزين المحلي للموبايل:** Hive (NoSQL) + SQLite (sqflite) — Offline-first

### أدوات وبيئة التطوير
- **التحرير:** Visual Studio Code / Flutter IDE
- **التحليل:** ESLint (Next.js)، Dart analyzer
- **التوثيق:** README.md بالعربية والإنجليزية
- **البيلد:** Flutter build_runner (retrofit_generator, json_serializable, hive_generator, injectable_generator)

---

## 📁 هيكل المشروع

```
Taqseet pro/
│
├── api/                              # 🖥️ Backend API (Node.js + Express)
│   ├── src/
│   │   ├── app.js                    # ★ نقطة الدخول الرئيسية (Express server)
│   │   ├── config/
│   │   │   ├── supabase.js           #   اتصال Supabase (anon + service role)
│   │   │   └── constants.js          #   ثوابت: أكواد الخطأ، رسائل عربية، أدوار المستخدمين
│   │   ├── controllers/              #   منطق الأعمال (7 ملفات)
│   │   │   ├── authController.js
│   │   │   ├── customersController.js
│   │   │   ├── guarantorsController.js
│   │   │   ├── installmentsController.js
│   │   │   ├── paymentsController.js
│   │   │   ├── productsController.js
│   │   │   └── syncController.js
│   │   ├── routes/                   #   تعريف مسارات API (14 ملف)
│   │   │   ├── auth.js
│   │   │   ├── customers.js
│   │   │   ├── guarantors.js
│   │   │   ├── products.js
│   │   │   ├── installments.js
│   │   │   ├── payments.js
│   │   │   ├── sync.js
│   │   │   ├── admin.js
│   │   │   ├── dashboard.js
│   │   │   ├── reports.js
│   │   │   ├── store.js
│   │   │   ├── plans.js
│   │   │   ├── cash-sales.js
│   │   │   └── telegram.js
│   │   ├── middleware/               #   مصادقة، تحقق اشتراك، تدقيق، معالجة أخطاء
│   │   │   ├── auth.js
│   │   │   ├── checkSubscription.js
│   │   │   ├── audit.js
│   │   │   └── errorHandler.js
│   │   ├── services/                 #   خدمات منطق الأعمال (7 ملفات)
│   │   │   ├── installmentCalculator.js  # حاسبة الأقساط
│   │   │   ├── receiptGenerator.js       # توليد الإيصالات (A4 + حراري)
│   │   │   ├── syncService.js            # مزامنة البيانات
│   │   │   ├── emailService.js
│   │   │   ├── notificationService.js
│   │   │   ├── telegramService.js
│   │   │   └── templateService.js
│   │   ├── cron/                     #   مهام مجدولة (3 ملفات)
│   │   │   ├── expiryNotifications.js
│   │   │   ├── dueInstallmentsNotifications.js
│   │   │   └── backupScheduler.js
│   │   └── utils/
│   │       └── errorHandler.ts
│   ├── database/
│   │   └── migrations/               # SQL migrations
│   ├── backups/                      # نسخ احتياطية تلقائية (JSON)
│   ├── .env                          # المتغيرات البيئية الفعلية (مهمل)
│   ├── .env.example
│   ├── package.json
│   └── README.md / README-ARABIC.md
│
├── web/                              # 🌐 Web App (Next.js 14)
│   ├── src/app/
│   │   ├── layout.tsx                # الجذر: Tajawal font, RTL, ThemeProvider
│   │   ├── page.tsx                  # الصفحة الرئيسية (ترحيب + خطط الأسعار)
│   │   ├── globals.css
│   │   ├── login/
│   │   ├── register/
│   │   ├── activate/
│   │   ├── reset-password/
│   │   ├── admin/
│   │   ├── app/                      # (store) صفحات التطبيق بعد تسجيل الدخول
│   │   ├── (store)/
│   │   └── (app)/
│   ├── src/components/
│   │   └── ui/                       # Button, Card, Input + LoadingSpinner
│   ├── src/context/
│   │   └── ThemeContext.tsx
│   ├── src/lib/
│   │   ├── utils.ts
│   │   └── exportService.ts
│   ├── .env.local
│   ├── next.config.js                # i18n: ar, appDir
│   ├── tailwind.config.js
│   └── tsconfig.json
│
├── admin/                            # 🔐 Admin Panel (Next.js 15)
│   ├── src/app/
│   │   ├── layout.tsx                # الجذر: Inter + Tajawal, RTL, ThemeProvider
│   │   ├── page.tsx                  # إعادة توجيه تلقائي → /login أو /dashboard
│   │   ├── globals.css
│   │   ├── login/
│   │   ├── dashboard/
│   │   ├── stores/
│   │   ├── super-admins/
│   │   ├── activation-codes/
│   │   ├── plans/
│   │   ├── cash-sales/
│   │   ├── backup/
│   │   ├── audit/
│   │   ├── notifications/
│   │   ├── register-super-admin/
│   │   ├── reset-password/
│   │   └── unauthorized/
│   ├── src/components/               # shadcn/ui components
│   ├── src/context/
│   │   └── ThemeContext.tsx
│   ├── src/lib/
│   │   ├── utils.ts
│   │   └── errorHandler.ts
│   ├── src/services/
│   │   └── storageService.js
│   ├── src/config/
│   ├── src/cron/
│   ├── src/routes/
│   ├── middleware.ts                 # حماية: super_admin فقط
│   ├── next.config.ts
│   ├── tailwind.config.js
│   ├── components.json               # shadcn/ui config
│   └── tsconfig.json
│
├── mobile/                           # 📱 Mobile App 1 (Flutter - "marsa")
│   └── lib/
│       ├── main.dart                 # ★ نقطة الدخول (Supabase init + SplashScreen)
│       ├── screens/                  # 14 شاشة (main_navigation, login, dashboard,
│       │                             #   customers, installment_details, payment, etc.)
│       ├── services/                 # 17 خدمة (api_client, sync, auth, pdf, local_db, etc.)
│       ├── providers/                # Provider state management
│       ├── models/
│       ├── core/                     # theme, constants
│       └── widgets/
│
├── mobileApp/                        # 📱 Mobile App 2 (Flutter - "marsa_mobile")
│   └── lib/
│       ├── main.dart                 # ★ نقطة الدخول (Bloc + Provider + Hive + SQLite)
│       ├── presentation/             # screens (auth, customers, installments, etc.)
│       ├── services/                 # api, database (hive+sqlite), sync service
│       ├── data/                     # طبقة البيانات
│       └── core/                     # config, theme, constants
│
├── AppNew/                           # 📱 Mobile App 3 (Flutter - "marsa_app" — تم التنفيذ)
│   └── lib/
│       ├── main.dart                 # ★ نقطة الدخول (Bloc + Hive + SQLite + Supabase + Sync)
│       ├── app.dart                  # MaterialApp, Theme, RTL, Routing, MultiBlocProvider
│       ├── core/                     # config, theme, constants, utils, logger, widgets
│       ├── data/                     # models (10), repositories (7), datasources (4)
│       ├── services/                 # sync, print, auth, connectivity (4 files)
│       └── presentation/            # blocs (7 features), screens (18 screen files), providers (2)
│   ├── assets/
│   │   ├── fonts/                    # Tajawal-Regular.ttf, Tajawal-Bold.ttf
│   │   └── images/                   # (لإضافة شعار مرساة)
│   ├── test/
│   │   ├── data/
│   │   ├── services/
│   │   └── presentation/
│
├── .env.shared                       # المتغيرات المشتركة (Supabase URL, Keys, JWT Secret)
├── config.yml                        # (فارغ حالياً)
├── analyze_output.txt                # Dart lint warnings
└── مهم.txt                            # كلمات مرور Supabase
```

---

## 🔑 الملفات الحرجة

| الملف | الوظيفة | ملاحظات |
|-------|---------|---------|
| `api/src/app.js` | نقطة دخول الخادم، تحميل الـ routes والميدلوير والـ cron | يشتغل على port 3000، يحتوي health check |
| `api/src/config/supabase.js` | إنشاء عميل Supabase (anon + service role) | service_role يتجاوز RLS |
| `api/src/config/constants.js` | أكواد الأخطاء، رسائل عربية، أدوار المستخدمين | جميع الرسائل بالعربية |
| `api/src/middleware/auth.js` | مصادقة JWT + تحقق super_admin | يتحقق من `is_active` للمحل |
| `api/src/middleware/checkSubscription.js` | التحقق من صلاحية الاشتراك | super_admin يتجاوز |
| `api/src/routes/auth.js` | جميع مسارات المصادقة (login, activate, register-trial, forgot-password, etc.) | **أطول ملف routes (~968 سطراً)** |
| `api/src/services/installmentCalculator.js` | حاسبة الأقساط (daily/weekly/monthly) | يستخدم moment.js |
| `api/src/services/receiptGenerator.js` | توليد HTML للإيصالات (A4 + thermal 58mm/80mm) مع QR | يدعم الطباعة الحرارية |
| `api/src/cron/expiryNotifications.js` | إشعارات انتهاء الاشتراك (يومياً 9:00 صباحاً) | يدعم تلجرام + واتساب + إيميل |
| `api/src/cron/backupScheduler.js` | نسخ احتياطي تلقائي | يحفظ JSON في `api/backups/` |
| `web/src/app/layout.tsx` | جذر Web App | RTL, Tajawal font, ThemeProvider |
| `admin/src/app/layout.tsx` | جذر Admin Panel | RTL, Inter + Tajawal, ThemeProvider |
| `admin/middleware.ts` | حماية مسارات Admin | يسمح فقط لـ super_admin |
| `mobile/lib/main.dart` | نقطة دخول الموبايل الأول | Provider + Supabase init |
| `mobileApp/lib/main.dart` | نقطة دخول الموبايل الثاني | Bloc + Provider + Hive + SQLite init |

---

## 🗄️ قاعدة البيانات

### الجداول / Collections

| الجدول | الحقول الأساسية | العلاقات |
|--------|----------------|----------|
| **stores** | id, name, owner_name, phone, address, city, logo_url, receipt_header/footer, default_currency, plan_id, subscription_start/end, is_active, telegram_chat_id, notification_settings | → subscription_plans |
| **users** | id, store_id, username, password_hash, full_name, phone, email, role (super_admin/store_owner/manager/employee), can_delete/edit/view_reports, is_active | → stores |
| **customers** | id, store_id, full_name, phone, national_id, address, id_doc_url, extra_docs (JSONB), telegram_chat_id | → stores |
| **guarantors** | id, store_id, customer_id, full_name, phone, relationship | → stores, customers |
| **products** | id, store_id, name, description, quantity, price_iqd, price_usd, cost_price_iqd/usd, category, sku, min_stock | → stores |
| **installment_plans** | id, store_id, customer_id, product_id, products (JSONB), total_price, down_payment, financed_amount, remaining_amount, total_paid, currency, frequency, start_date, end_date, status, profit, installment_amount, installments_count | → stores, customers |
| **payment_schedule** | id, plan_id, store_id, installment_no, due_date, amount, status (pending/paid/overdue) | → installment_plans |
| **payments** | id, plan_id, schedule_id, store_id, received_by, amount_paid, payment_date, is_early, receipt_number, notes, currency | → installment_plans, payment_schedule |
| **activation_codes** | id, code, plan_id, is_used, used_at, expires_at, store_id | → subscription_plans, stores |
| **audit_logs** | id, store_id, user_id, action, table_name, record_id, old_data (JSONB), new_data (JSONB), ip_address | → stores, users |
| **sync_queue** | id, store_id, operation, table_name, record_id, data (JSONB), status, conflict | → stores |
| **subscription_plans** | id, name, duration_days, price_iqd, max_customers, max_employees | — |
| **password_resets** | id, user_id, token, expires_at | → users |

---

## 🔗 نقاط الـ API

| Method | Endpoint | الوظيفة |
|--------|----------|---------|
| GET | `/health` | التحقق من صحة الخادم |
| POST | `/api/auth/login` | تسجيل الدخول (JWT) |
| POST | `/api/auth/activate` | تفعيل حساب بكود تفعيل |
| POST | `/api/auth/register-trial` | تسجيل فترة تجريبية 14 يوم |
| GET | `/api/auth/me` | جلب بيانات المستخدم الحالي |
| POST | `/api/auth/refresh` | تجديد JWT token |
| POST | `/api/auth/verify-code` | التحقق من صحة كود التفعيل |
| POST | `/api/auth/forgot-username` | استعادة اسم المستخدم (إيميل) |
| POST | `/api/auth/forgot-password` | طلب إعادة تعيين كلمة المرور |
| POST | `/api/auth/reset-password` | إعادة تعيين كلمة المرور |
| POST | `/api/auth/register-super-admin` | إنشاء super_admin جديد |
| GET | `/api/customers` | قائمة العملاء (بحث، تصفح) |
| POST | `/api/customers` | إضافة عميل جديد |
| GET | `/api/customers/:id` | تفاصيل عميل |
| PUT | `/api/customers/:id` | تحديث بيانات عميل |
| DELETE | `/api/customers/:id` | حذف عميل (يمنع إن كان لديه أقساط نشطة) |
| GET/POST | `/api/guarantors` | إدارة الكفلاء |
| GET/POST | `/api/products` | إدارة المنتجات |
| PUT/DELETE | `/api/products/:id` | تحديث/حذف منتج |
| PATCH | `/api/products/:id/stock` | تحديث المخزون |
| POST | `/api/installments/calculate` | حاسبة الأقساط (معاينة قبل الإنشاء) |
| POST | `/api/installments` | إنشاء خطة قسط جديدة (مع تنقيص المخزون) |
| GET | `/api/installments` | قائمة الأقساط (بحث، تصفية) |
| GET | `/api/installments/:id` | تفاصيل قسط + جدول الدفعات + المدفوعات |
| GET | `/api/installments/due-today` | الأقساط المستحقة اليوم |
| PUT | `/api/installments/:id/cancel` | إلغاء خطة قسط (مع إرجاع المخزون) |
| POST | `/api/payments` | تسجيل دفعة جديدة |
| POST | `/api/payments/full-settlement` | تسديد كامل المبلغ (مع خصم اختياري) |
| GET | `/api/payments/receipt/:receipt_number` | جلب بيانات وصل الدفع |
| GET | `/api/payments/receipt/:receipt_number/print` | طباعة الوصل |
| GET | `/api/payments/statement/:plan_id` | كشف حساب خطة قسط |
| POST | `/api/sync/push` | مزامنة: رفع بيانات من الموبايل |
| GET | `/api/sync/pull` | مزامنة: سحب بيانات للموبايل |
| GET | `/api/sync/conflicts` | جلب التعارضات |
| POST | `/api/sync/resolve-conflict` | حل التعارضات |
| GET/POST | `/api/admin/*` | إدارة النظام (super_admin) |
| GET | `/api/dashboard` | إحصائيات لوحة التحكم |
| GET | `/api/reports` | تقارير |
| GET/POST | `/api/store` | إدارة بيانات المحل |
| GET | `/api/plans` | خطط الاشتراك |
| GET/POST | `/api/cash-sales` | مبيعات نقدية |
| POST | `/api/telegram` | إرسال إشعار تلجرام |

---

## ⚙️ متغيرات البيئة المطلوبة

| المتغير | وصف الاستخدام | المصدر |
|---------|---------------|--------|
| `PORT` | منفذ الخادم (3000) | `api/.env` |
| `SUPABASE_URL` | رابط مشروع Supabase | `.env.shared`, `api/.env` |
| `SUPABASE_ANON_KEY` | مفتاح anon لـ Supabase | `.env.shared`, `api/.env` |
| `SUPABASE_SERVICE_ROLE_KEY` | مفتاح service_role (يتجاوز RLS) | `api/.env` |
| `JWT_SECRET` | سر توقيع JWT | `.env.shared`, `api/.env` |
| `NODE_ENV` | بيئة التشغيل (development/production) | `api/.env` |
| `RESEND_API_KEY` | مفتاح خدمة Resend للإيميلات | `api/.env` |
| `RESEND_FROM_EMAIL` | البريد المرسل للإيميلات | `api/.env` |
| `FRONTEND_URL` | رابط الواجهة الأمامية (لروابط إعادة التعيين) | `api/.env` |
| `NEXT_PUBLIC_API_URL` | رابط API للـ Web App | `web/.env.local` |
| `NEXT_PUBLIC_APP_NAME` | اسم التطبيق في Web App | `web/.env.local` |

---

## 📐 قواعد وأنماط المشروع

- **نمط التسمية:**
  - **API:** `camelCase` للمتغيرات والدوال، الملفات بـ `kebab-case` (`authController.js`, `checkSubscription.js`)
  - **Web/Admin:** `PascalCase` للمكونات، `camelCase` للمتغيرات، الملفات بـ `kebab-case`
  - **Flutter:** `snake_case` للملفات، `PascalCase` للكلاسات، `camelCase` للمتغيرات والدوال
  - **جداول Supabase:** `snake_case` (`installment_plans`, `payment_schedule`, `activation_codes`)

- **طريقة التعامل مع الأخطاء:**
  - جميع الردود تتبع التنسيق: `{ success: boolean, data?: any, error?: string, code?: string }`
  - `errorHandler.js` المركزي يلتقط الأخطاء غير المعالجة ويعيدها بتنسيق موحد
  - `createError(statusCode, code, message)` دالة مساعدة لإنشاء أخطاء مخصصة
  - في بيئة `development`، تُرسل تفاصيل الخطأ والـ Stack Trace

- **أسلوب كتابة الكود السائد:**
  - **API:** CommonJS (`require`/`module.exports`)، دوال async/await، فصل الـ Routes عن Controllers
  - **Web/Admin:** ES Modules + TypeScript، `'use client'` للمكونات التفاعلية
  - **Flutter:** Dart null-safety، `const` wherever possible
  - جميع التعليقات والرسائل والمتغيرات باللغة العربية

- **مكان وضع الملفات الجديدة:**
  - API route جديد → `api/src/routes/` + تسجيله في `api/src/app.js`
  - Controller جديد → `api/src/controllers/`
  - Service جديد → `api/src/services/`
  - Middleware جديد → `api/src/middleware/`
  - صفحة Web جديدة → `web/src/app/` (حسب المسار)
  - صفحة Admin جديدة → `admin/src/app/`
  - مكون Flutter جديد → `mobile/lib/widgets/` أو `mobileApp/lib/presentation/widgets/`
  - شاشة Flutter جديدة → `mobile/lib/screens/` أو `mobileApp/lib/presentation/screens/`

---

## 📝 سجل التعديلات

| التاريخ | التعديل | الملفات المتأثرة |
|---------|---------|-----------------|
| 2026-05-10 | إنشاء ملف PROJECT_MEMORY.md | PROJECT_MEMORY.md |
| 2026-05-10 | إضافة خطة تطبيق AppNew (marsa_app) — العمارة، الـ Milestones، والـ Tech Stack | PROJECT_MEMORY.md |
| 2026-05-10 | تنفيذ كامل لتطبيق AppNew — 78 ملف Dart، جميع الشاشات، الـ Blocs، الـ Repos، والـ Services | PROJECT_MEMORY.md, AppNew/lib/* |
| 2026-05-10 | إصلاح 16 مشكلة تحليل (analysis) — أخطاء في api_constants, storage_api, print_service, imports, unused fields/variables, deprecated `value` → `initialValue`, BuildContext async gaps | 11 ملفات في lib/ + test/widget_test.dart |
| 2026-05-10 | إضافة mocktail للاختبارات، إعادة هيكلة 7 Blocs لقبول Repository injection (للاختبار)، كتابة 45 اختبار وحدة لجميع الـ Blocs (جميعها تمر) | pubspec.yaml, 7 blocs, 8 test files |
| 2026-05-10 | استبدال AppConfig بنسخة mobileApp المدعمة (IP-based API URL, Supabase Storage bucket + helper methods)، تحديث api_constants، api_service، storage_api، main.dart | app_config.dart, api_constants.dart, api_service.dart, storage_api.dart, main.dart |
| 2026-05-11 | إصلاح 6 Repositories لقراءة `res['data']` بشكل صحيح (customer/product/installment/payment) + إضافة فلتر customerId للـ InstallmentRepository.getAll | customer_repository.dart, product_repository.dart, installment_repository.dart, payment_repository.dart |
| 2026-05-11 | تحديث CustomerModel (phoneAlt, notes) و ProductModel (sellPriceCash, sellPriceInstall, lowStockAlert, costPriceUsd) | customer_model.dart, product_model.dart |
| 2026-05-11 | إعادة هيكلة 5 شاشات لمطابقة تطبيق الويب: CustomerForm (صور+phone_alt+notes), ProductForm (عملة+فئة+تنبيه+أسعار), InstallmentForm (multi-step wizard), CashSale (drop-down منتج), Payment (بحث عميل+اختيار قسط+تسديد كامل+خصم) | customer_form_screen.dart, product_form_screen.dart, installment_form_screen.dart, cash_sale_screen.dart, payment_screen.dart |
| 2026-05-11 | إضافة CreateFullSettlement event + handling في PaymentBloc و PaymentRepository | payment_bloc.dart, payment_event.dart, payment_repository.dart |

---

## ⚠️ تحذيرات ونقاط حساسة

1. **🔴 SUPABASE_SERVICE_ROLE_KEY** موجود في `.env.shared` و `api/.env` و `مهم.txt` — هذا المفتاح يتجاوز كل قواعد RLS في Supabase. لا تنشره أبداً في git أو أي مكان عام.
2. **🔴 JWT_SECRET** مكشوف في `.env.shared` — يجب تغييره فوراً في الإنتاج. صلاحية الـ JWT الحالية **30 يوماً** (قد تكون طويلة).
3. **🔴 RESEND_API_KEY** مكشوف في `api/.env` — يجب حمايته في الإنتاج.
4. **`api/src/routes/auth.js`** يحتوي على **دالة `/register-trial` مكررة مرتين** (سطور 709-835 و 838-966) — هذا خطأ يجب إصلاحه.
5. **هناك تطبيقا موبايل (mobile/ و mobileApp/)** — يبدو أن `mobileApp/` هو الإصدار الأحدث (Offline-first مع Bloc). عند العمل على الموبايل، تأكد من أي إصدار تقصد.
6. **النسخ الاحتياطي التلقائي** يحفظ ملفات JSON في `api/backups/` — قد تتراكم الملفات وتستهلك مساحة.
7. **مزامنة Offline-first** معقدة: يوجد 3 خدمات مزامنة مختلفة (`syncService.js`, `unified_sync_service.dart`, `marsa_sync_service.dart`) — التعارضات تحتاج معالجة دقيقة.
8. **Admin middleware** في `admin/middleware.ts` يحمي جميع الصفحات عدا `/login` و `/register-super-admin`. أي صفحة جديدة يجب إضافتها إلى `publicPaths` إذا كانت عامة.

---

## 💡 سياق إضافي

- **نظام الاشتراكات:** كل متجر له `subscription_end`. Middleware يتحقق قبل كل طلب. دور `super_admin` يتجاوز كل القيود. يوجد فترة تجريبية 14 يوم.
- **طباعة الإيصالات:** تدعم 3 أنواع (A4، حراري 58mm، حراري 80mm) مع QR code. يتم توليد HTML ثم طباعته.
- **الإشعارات:** 3 قنوات — تلجرام (chat_id لكل متجر/عميل)، واتساب (رابط)، إيميل (عبر Resend). مع `templateService` لقالب النصوص.
- **سجل التدقيق:** جدول `audit_logs` يسجل كل عملية مهمة (user_id, action, table_name, old/new data, ip).
- **المشروع موجه للسوق العراقي:** العملة الأساسية IQD, اللغة العربية, توقيت بغداد.
- **المبيعات النقدية:** يوجد route منفصل `api/src/routes/cash-sales.js` للمبيعات النقدية (غير الأقساط).

---

---

## 🆕 تطبيق AppNew — marsa_app (الموبايل المبسط)

### 1. الافتراضات والمبررات

| الافتراض | المبرر |
|----------|--------|
 | التطبيق موجه لمستخدمي الموبايل الذين يحتاجون سرعة في العمل اليومي | ورد في المتطلبات: "أبسط من تطبيق الويب للسرعة في العمل اليومي" |
| API الحالي (Express + Supabase) كافٍ ولا يحتاج تعديل | الـ sync endpoints موجودة مسبقاً |
| الصور ترفع إلى Supabase Storage (bucket: `customer_docs`) | آلية الرفع موجودة في الـ API عبر service_role |
| الطباعة عبر Bluetooth طابعة حرارية 50mm/80mm | `printing` package + `receiptGenerator.js` موجود |
| المصادقة: JWT + Biometric (بعد أول تسجيل دخول) | `local_auth` package, API يدعم JWT |
| Hive للتخزين المحلي (NoSQL) + SQLite للعلاقات | نفس نمط الـ mobileApp الموجود |

### 2. نطاق المشروع — NO FEATURE CREEP

**مسموح به فقط:**
1. الشاشات العامة قبل تسجيل الدخول (Landing, Login, Activate, Register)
2. الشاشات الخمس: Home, Customers, Products, Installments, Cash Sales
3. مزامنة Offline-first (push/pull مع Queue)
4. طباعة الإيصالات عبر Bluetooth
5. تسجيل الدخول بالبصمة بعد أول مرة
6. رفع صور العملاء + المستمسكات إلى Supabase Storage (مع ضغط)

**مرفوض صراحة:**
- التقارير المتقدمة (موجودة في Web)
- إدارة الموظفين (موجودة في Web)
- إدارة الإعدادات (موجودة في Web)
- سجل التدقيق (موجودة في Web)
- QR Scanner (غير مطلوب لهذا الإصدار)
- إشعارات push (غير مطلوبة)

### 3. رحلة المستخدم (User Journey)

```
[Splash] → [Landing (معلومات النظام + الخطط)]
              ├── [Login] → [Biometric (المرة الثانية+)] → [Home]
              ├── [Activate Code] → [Login] → [Home]
              └── [Register Trial] → [Login] → [Home]

[Home]
  ├── عرض: اسم المحل, إحصائيات (العملاء, الأقساط النشطة, تحصيلات اليوم, المستحقة, المتأخرة)
  ├── أزرار سريعة: إضافة عميل, قسط جديد, منتج جديد, تسديد دفعة
  ├── آخر الأقساط المضافة (قائمة)
  └── Bottom Navigation: [Home] [العملاء] [المخزن] [الأقساط] [بيع نقدي]

[العملاء]
  ├── قائمة العملاء + بحث
  ├── زر إضافة عميل
  └── [تفاصيل عميل]
       ├── معلومات العميل + صور (بطاقة وطنية, سكن, وجه)
       ├── الأقساط النشطة للعميل
       └── [تفاصيل القسط] ← مشترك مع قسم الأقساط
            ├── معلومات القسط
            ├── جدول الدفعات
            ├── الوصولات
            └── طباعة وصل (Bluetooth 50/80mm)

[المخزن]
  ├── قائمة المنتجات + بحث
  ├── إضافة/تعديل منتج
  └── حذف منتج

[الأقساط]
  ├── قائمة الأقساط + بحث + تصفية
  ├── إضافة قسط
  └── [تفاصيل القسط] ← مشترك مع العملاء

[بيع نقدي]
  └── شاشة البيع النقدي (مطابقة للـ Web)
```

### 4. العمارة التقنية (Surgical Architecture)

```
AppNew/
├── lib/
│   ├── main.dart                          # نقطة الدخول: init Hive, SQLite, Supabase, Bloc
│   ├── app.dart                           # MaterialApp + Theme + RTL + Routing
│   │
│   ├── core/                              # طبقة مشتركة — ONLY shared logic
│   │   ├── config/
│   │   │   ├── app_config.dart            # البيئة، الـ API URL، الـ Supabase config
│   │   │   └── theme/
│   │   │       ├── app_theme.dart         # ألوان "مرساة" نفس الهوية البصرية (Navy #0A192F, Electric #0066FF, إلخ)
│   │   │       ├── app_colors.dart        # Color constants
│   │   │       └── app_text_styles.dart   # Tajawal font styles
│   │   ├── constants/
│   │   │   ├── api_constants.dart         # Endpoints
│   │   │   └── app_constants.dart         # ثوابت عامة
│   │   ├── utils/
│   │   │   ├── validators.dart            # مدخلات الحقول
│   │   │   ├── formatters.dart            # تنسيق عملة، تاريخ
│   │   │   └── image_utils.dart           # ضغط الصور قبل الرفع
│   │   ├── logger/
│   │   │   └── app_logger.dart            # Async logging (non-blocking, levels: error/warn/info/debug)
│   │   └── widgets/                       # Widgets مشتركة بين أكثر من feature
│   │       ├── loading_widget.dart
│   │       ├── error_widget.dart
│   │       ├── empty_state_widget.dart
│   │       ├── search_bar.dart
│   │       └── confirmation_dialog.dart
│   │
│   ├── data/                              # طبقة البيانات (Models + Repositories + DataSources)
│   │   ├── models/                        # Data models مع JSON serialization + Hive adapters
│   │   │   ├── user_model.dart
│   │   │   ├── store_model.dart
│   │   │   ├── customer_model.dart
│   │   │   ├── product_model.dart
│   │   │   ├── installment_model.dart
│   │   │   ├── payment_model.dart
│   │   │   ├── schedule_model.dart
│   │   │   ├── cash_sale_model.dart
│   │   │   ├── plan_model.dart
│   │   │   └── sync_queue_model.dart
│   │   ├── repositories/                  # Abstract interface + implementations
│   │   │   ├── auth_repository.dart
│   │   │   ├── customer_repository.dart
│   │   │   ├── product_repository.dart
│   │   │   ├── installment_repository.dart
│   │   │   ├── payment_repository.dart
│   │   │   ├── cash_sale_repository.dart
│   │   │   ├── dashboard_repository.dart
│   │   │   └── sync_repository.dart
│   │   └── datasources/                   # Local + Remote
│   │       ├── local/
│   │       │   ├── hive_service.dart      # Hive boxes: customers, products, etc.
│   │       │   └── sqlite_service.dart    # SQLite: payment_schedule, sync_queue
│   │       └── remote/
│   │           ├── api_service.dart       # Dio client + interceptors (JWT, retry, logging)
│   │           ├── auth_api.dart
│   │           ├── customer_api.dart
│   │           ├── product_api.dart
│   │           ├── installment_api.dart
│   │           ├── payment_api.dart
│   │           ├── cash_sale_api.dart
│   │           ├── dashboard_api.dart
│   │           └── storage_api.dart       # Supabase Storage لرفع صور العملاء
│   │
│   ├── services/                          # خدمات عمومية
│   │   ├── sync_service.dart              # Offline-first sync: queue → push/pull → resolve
│   │   ├── print_service.dart             # Bluetooth printing 50mm/80mm
│   │   ├── auth_service.dart              # JWT storage (flutter_secure_storage) + biometric
│   │   └── connectivity_service.dart      # رصد الاتصال (connectivity_plus)
│   │
│   └── presentation/                      # UI Layer (Bloc per feature)
│       ├── providers/                     # Provider للـ theme وحالات بسيطة
│       │   ├── theme_provider.dart
│       │   └── auth_provider.dart
│       │
│       ├── blocs/                         # Business Logic Components
│       │   ├── auth_bloc/
│       │   │   ├── auth_bloc.dart
│       │   │   ├── auth_event.dart
│       │   │   └── auth_state.dart
│       │   ├── customer_bloc/
│       │   │   ├── customer_bloc.dart
│       │   │   ├── customer_event.dart
│       │   │   └── customer_state.dart
│       │   ├── product_bloc/
│       │   ├── installment_bloc/
│       │   ├── payment_bloc/
│       │   ├── dashboard_bloc/
│       │   └── cash_sale_bloc/
│       │
│       └── screens/                       # شاشة واحدة لكل feature
│           ├── landing/
│           │   ├── splash_screen.dart
│           │   └── landing_screen.dart     # معلومات النظام + خطط + أزرار (Login/Activate/Trial)
│           ├── auth/
│           │   ├── login_screen.dart       # اسم مستخدم + كلمة مرور + بصمة (بعد أول مرة)
│           │   ├── activate_screen.dart    # تفعيل كود
│           │   └── register_screen.dart    # تسجيل تجريبي 14 يوم
│           ├── home/
│           │   └── home_screen.dart        # الإحصائيات + الأزرار السريعة + آخر الأقساط
│           ├── customers/
│           │   ├── customers_screen.dart   # قائمة + بحث
│           │   ├── customer_form_screen.dart # إضافة/تعديل + صور
│           │   └── customer_detail_screen.dart # تفاصيل + أقساط نشطة
│           ├── products/
│           │   ├── products_screen.dart    # قائمة + بحث
│           │   └── product_form_screen.dart # إضافة/تعديل
│           ├── installments/
│           │   ├── installments_screen.dart # قائمة + بحث
│           │   ├── installment_form_screen.dart # إضافة قسط
│           │   └── installment_detail_screen.dart # تفاصيل + جدول دفعات + وصولات + طباعة
│           ├── cash_sales/
│           │   └── cash_sale_screen.dart   # بيع نقدي
│           └── shared/                     # شاشات مشتركة
│               └── payment_screen.dart     # تسديد دفعة (تستخدم من Home/Customers/Installments)
│
├── assets/
│   ├── images/                            # صور ثابتة (logo, splash)
│   ├── icons/                             # SVG icons
│   └── fonts/                             # Tajawal (Regular + Bold)
│
├── pubspec.yaml
├── analysis_options.yaml
└── test/
    ├── data/
    ├── services/
    └── presentation/
```

### 5. استراتيجية المزامنة (Offline-first Sync)

```
                   ┌─────────────────────────┐
                   │     Local Hive/SQLite    │
                   │  (primary data source)   │
                   └──────────┬──────────────┘
                              │ all CRUD goes here first
                              ▼
                   ┌─────────────────────────┐
                   │     Sync Queue (SQLite)  │
                   │  { operation, table,     │
                   │    record_id, data,      │
                   │    status, timestamp }   │
                   └──────────┬──────────────┘
                              │ on connectivity
                              ▼
                   ┌─────────────────────────┐
                   │   POST /api/sync/push    │
                   │   GET  /api/sync/pull    │
                   └──────────┬──────────────┘
                              │
                   ┌──────────▼───────────┐
                   │  Supabase (PostgreSQL)│
                   │  (source of truth)    │
                   └──────────────────────┘
```

- **القراءة:** دائماً من Hive أولاً، ثم تحديث خلفي من API عند الاتصال
- **الكتابة:** دائماً إلى Hive/SQLite محلياً أولاً، ثم إضافة إلى Sync Queue
- **الرفع:** عند توفر الاتصال، يرفع Sync Queue بالترتيب (FIFO) مع معالجة التعارضات
- **السحب:** عند توفر الاتصال، يسحب آخر التحديثات (timestamp-based incremental sync)

### 6. استراتيجية الـ Logging (غير حظرية)

```dart
// app_logger.dart — levels: error, warn, info, debug
// - Non-blocking: uses async file write + ring buffer
// - لا يخزن في ملف في الإنتاج (يكتفى بـ debugPrint في development)
// - يرسل errors إلى remote logging service (اختياري)
// - المستوى الافتراضي: info في الإنتاج، debug في التطوير
```

### 7. الهوية البصرية (نفس تطبيق الويب)

| العنصر | القيمة |
|--------|--------|
| Primary | Navy `#0A192F` |
| Accent | Electric `#0066FF` |
| Success | `#28A745` |
| Warning | `#FFC107` |
| Danger | `#DC3545` |
| Background | `#F0F2F5` (light), `#0D1117` (dark) |
| Card | `#FFFFFF` (light), `#161B22` (dark) |
| Font | Tajawal (Regular 400, Bold 700) |
| Direction | RTL |
| Logo | شعار مرساة (Anchor icon) |

### 8. إصدارات الحزم (Protocol 1 — Dependency Audit)

 بناءً على تاريخ 2026-05-10 و Flutter 3.41.4 / Dart 3.11.1:

| الحزمة | الإصدار المستقر | ملاحظات |
|--------|-----------------|---------|
| flutter_bloc | ^9.0.0 | Bloc 9.x متوافق مع Flutter 3.41 |
| provider | ^6.1.2 | متوافق |
| get_it | ^8.0.3 | DI |
| hive | ^2.2.3 | تخزين محلي NoSQL |
| hive_flutter | ^1.1.0 | |
| sqflite | ^2.4.1 | SQLite محلي |
| dio | ^5.7.1 | HTTP client |
| supabase_flutter | ^2.8.0 | مع Flutter 3.41 — استخدم ^2.8.x |
| local_auth | ^2.3.0 | بصمة/وجه |
| flutter_secure_storage | ^9.2.2 | تخزين JWT |
| image_picker | ^1.1.2 | التقاط صور |
| flutter_image_compress | ^2.3.0 | ضغط الصور قبل الرفع |
| printing | ^5.14.0 | طباعة حرارية |
| pdf | ^3.11.0 | توليد PDF للوصول |
| connectivity_plus | ^6.1.0 | رصد الإنترنت |
| intl | ^0.20.2 | توطين عربي |
| uuid | ^4.5.1 | UUID للـ offline records |
| path_provider | ^2.1.5 | مسارات التخزين |
| cached_network_image | ^3.4.1 | عرض الصور مع caching |
| equatable | ^2.0.7 | Equality for Bloc states |
| dartz | ^0.10.1 | Either for error handling |
| logger | ^2.5.0 | Logging |

---

## 📋 خطة العمل — Milestones قابلة للتحقق

### M1: مشروع Flutter + البنية التحتية
**الهدف:** إنشاء مشروع Flutter صالح مع جميع التبعيات والهيكل الأساسي
- [ ] `flutter create` في `AppNew/`
- [ ] إضافة جميع الـ dependencies إلى pubspec.yaml
- [ ] تعريف هيكل المجلدات (core, data, services, presentation)
- [ ] إعداد Hive و SQLite و Supabase initialization
- [ ] إعداد Theme (RTL, Tajawal font, ألوان مرساة)
- [ ] إنشاء `app_logger.dart`
- **التحقق:** `flutter analyze` بدون أخطاء + التطبيق يعمل ويعرض SplashScreen

### M2: شاشات المصادقة (Landing, Login, Activate, Register)
**الهدف:** تدفق تسجيل الدخول الكامل مع Biometric بعد أول مرة
- [ ] SplashScreen
- [ ] LandingScreen (معلومات النظام + خطط + أزرار)
- [ ] LoginScreen + AuthBloc (JWT + Secure Storage)
- [ ] Biometric (local_auth) — يطلب بصمة بعد أول تسجيل دخول ناجح
- [ ] ActivateScreen (تفعيل كود)
- [ ] RegisterScreen (تسجيل تجريبي 14 يوم)
- **التحقق:**用户可以 تسجيل الدخول، الخروج، إعادة الدخول بالبصمة، تفعيل كود، تسجيل تجريبي

### M3: الشاشة الرئيسية (Home) + Dashboard
**الهدف:** عرض إحصائيات المحل مع أزرار الوصول السريع
- [ ] DashboardBloc + DashboardRepository + DashboardAPI
- [ ] HomeScreen: إحصائيات (عملاء, أقساط نشطة, تحصيلات, مستحقة, متأخرة)
- [ ] أزرار سريعة (إضافة عميل, قسط جديد, منتج جديد, تسديد دفعة)
- [ ] قائمة آخر الأقساط المضافة
- [ ] Bottom Navigation Bar (5 أقسام)
- **التحقق:** Dashboard يعرض بيانات حقيقية من API (أو من Hive عند عدم الاتصال)

### M4: قسم العملاء
**الهدف:** CRUD كامل للعملاء مع رفع الصور إلى Supabase Storage
- [ ] CustomerBloc + CustomerRepository + CustomerAPI + StorageAPI
- [ ] CustomersScreen (قائمة + بحث)
- [ ] CustomerFormScreen (إضافة/تعديل + صور: عميل + بطاقة وطنية + سكن + وجه أمامي/خلفي)
- [ ] ضغط الصور قبل الرفع (flutter_image_compress)
- [ ] حذف الصور القديمة عند التعديل/الحذف
- [ ] CustomerDetailScreen (معلومات العميل + أقساطه النشطة)
- **التحقق:** يمكن إضافة عميل مع صور، عرضها، تعديلها، حذفها — مع تخزين محلي ومزامنة

### M5: قسم المنتجات
**الهدف:** CRUD كامل للمنتجات
- [ ] ProductBloc + ProductRepository + ProductAPI
- [ ] ProductsScreen (قائمة + بحث)
- [ ] ProductFormScreen (إضافة/تعديل)
- [ ] حذف منتج
- **التحقق:** يمكن إضافة، عرض، تعديل، حذف منتج — مع مزامنة Offline

### M6: قسم الأقساط
**الهدف:** إدارة الأقساط الكاملة مع جدول الدفعات والوصولات والطباعة
- [ ] InstallmentBloc + InstallmentRepository + InstallmentAPI
- [ ] PaymentBloc + PaymentRepository + PaymentAPI
- [ ] InstallmentsScreen (قائمة + بحث + تصفية)
- [ ] InstallmentFormScreen (إضافة قسط)
- [ ] InstallmentDetailScreen (معلومات القسط + جدول الدفعات + الوصولات)
- [ ] طباعة الوصولات (Bluetooth 50mm/80mm) عبر PrintService
- [ ] PaymentScreen (تسديد دفعة) ← مشترك مع Home
- **التحقق:** يمكن إنشاء قسط، عرض جدول الدفعات، تسديد دفعة، طباعة وصل — Offline

### M7: قسم البيع النقدي
**الهدف:** شاشة بيع نقدي مبسطة
- [ ] CashSaleBloc + CashSaleRepository + CashSaleAPI
- [ ] CashSaleScreen
- **التحقق:** يمكن تسجيل بيع نقدي مع تخزين محلي + مزامنة

### M8: المزامنة + الاختبارات + التحسين
**الهدف:** مزامنة Offline-first كاملة + اختبارات + تحسين أداء
- [x] SyncService: queue → push → pull → conflict resolution
- [x] ConnectivityService: رصد الاتصال وتشغيل المزامنة تلقائياً
- [x] اختبارات الوحدة للـ Blocs (45 اختبار، كلها تمر)
- [ ] اختبارات واجهة (widget tests) للشاشات الرئيسية ← مؤجلة لاختبار التكامل
- [x] `flutter analyze` — 0 errors, 0 warnings
- **التحقق:** التطبيق يعمل كاملًا بدون إنترنت، ويتم المزامنة عند توفر الاتصال

---

## 🧩 ORPHANS & PENDING (نواقص وملاحظات)

### ✅ تم الإنجاز (M1 + M2)
- [x] مشروع Flutter منشأ في `AppNew/` (marsa_app)
- [x] جميع التبعيات في pubspec.yaml (Flutter 3.41.4, Dart 3.11.1)
- [x] هيكل المجلدات الكامل (core, data, services, presentation)
- [x] Hive + SQLite + Supabase initialization في main.dart
- [x] Theme (RTL, Tajawal font, ألوان مرساة Navy+Electric)
- [x] `app_logger.dart` (Async Logging, 4 levels)
- [x] جميع الموديلات (10 ملفات: User, Store, Customer, Product, Installment, Payment, Schedule, CashSale, Plan, DashboardStats, AuthResponse, SyncQueue)
- [x] جميع الـ Repositories (7 ملفات: Auth, Customer, Product, Installment, Payment, Dashboard, CashSale)
- [x] جميع الـ DataSources (API Service, Hive, SQLite, Storage)
- [x] جميع الـ Services (Auth, Connectivity, Sync, Print)
- [x] جميع الـ Blocs (7: Auth, Dashboard, Customer, Product, Installment, Payment, CashSale)
- [x] SplashScreen + LandingScreen + LoginScreen (مع Biometric) + ActivateScreen + RegisterScreen
- [x] MainShell (Bottom Navigation 5 tabs: الرئيسية, العملاء, المخزن, الأقساط, بيع نقدي)
- [x] HomeScreen (إحصائيات + أزرار سريعة + آخر الأقساط)
- [x] CustomersScreen + CustomerFormScreen (مع صور + ضغط) + CustomerDetailScreen
- [x] ProductsScreen + ProductFormScreen
- [x] InstallmentsScreen (مع تصفية) + InstallmentFormScreen + InstallmentDetailScreen (جدول دفعات + وصولات + طباعة)
- [x] CashSaleScreen + PaymentScreen

### 🔲 متبقي للاختبار والتحسين
- [ ] **Bluetooth printing:** يحتاج اختبار على جهاز فعلي مع طابعة 50mm و 80mm
- [ ] **Biometric flow:** يحتاج جهاز يدعم biometric لتجربة flow "first login → save token → biometric next time"
- [ ] **Supabase Storage bucket:** إنشاء bucket `customer_docs` مع RLS policy
- [ ] **Sync conflict resolution:** التعارضات حالياً Last-Write-Wins — يحتاج تحسين
- [ ] **Image compression:** ضغط الصور قبل الرفع (flutter_image_compress) — نسبة الضغط المثلى 75%
- [ ] **Fonts:** Tajawal-Regular.ttf + Tajawal-Bold.ttf موجودان في assets/fonts/
- [x] **اختبارات الوحدة:** 45 اختبار لجميع الـ 7 Blocs (كلها تمر باستخدام mocktail)
- [x] **`flutter analyze`:** 0 errors, 0 warnings (14 infos: RadioListTile deprecated + convertHtml deprecated)
- [x] **Blocs refactored:** جميع الـ 7 Blocs تقبل Repository injection للاختبار
- [ ] **Admin routes:** إضافة admin routes للـ `app.dart` لجعل `onGenerateRoute` كاملة
- [x] **API base URL:** تم تغيير `AppConfig` إلى نسخة mobileApp المدعمة — IP-based (`192.168.0.127:3000`)، مع Supabase Storage bucket (`customers`) و helper methods للروابط
- [ ] **تعديل `API_IP` في `app_config.dart`:** غيّر القيمة `192.168.0.127` إلى IP جهازك الفعلي قبل تشغيل التطبيق على جهاز حقيقي

### 📊 حالة الـ Milestones
| Milestone | الحالة |
|-----------|--------|
| M1: مشروع Flutter + البنية التحتية | ✅ مكتمل |
| M2: شاشات المصادقة (Landing, Login, Activate, Register) | ✅ مكتمل |
| M3: الشاشة الرئيسية (Home) + Dashboard | ✅ مكتمل |
| M4: قسم العملاء | ✅ مكتمل |
| M5: قسم المنتجات | ✅ مكتمل |
| M6: قسم الأقساط | ✅ مكتمل |
| M7: قسم البيع النقدي | ✅ مكتمل |
| M8: المزامنة + الاختبارات + التحسين | ✅ مكتمل (باستثناء اختبارات التكامل) |

---





في كل محادثة جديدة:
1. اقرأ هذا الملف أولاً قبل أي شيء
2. بعد أي تعديل، حدّث فوراً:
   - سجل التعديلات (أضف صفاً جديداً)
   - آخر تحديث في الأعلى
   - أي قسم تأثر بالتعديل
3. لا تنتظر إذناً للتحديث، افعله تلقائياً
