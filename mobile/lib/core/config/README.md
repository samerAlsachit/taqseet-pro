# إعدادات API - API Configuration

## ⚡ تغيير IP الخادم بسرعة

لتغيير IP الخادم عند الانتقال لجهاز آخر:

1. افتح الملف: `lib/core/config/app_config.dart`
2. غيّر السطر:
```dart
static const String API_IP = '192.168.1.100'; // ← غيّر هذا فقط
```n
3. أعد تشغيل التطبيق

## 📁 الملفات

| الملف | الوصف |
|-------|-------|
| `app_config.dart` | إعدادات API الأساسية (IP, Port) |
| `api_endpoints.dart` | روابط API الكاملة |

## 💡 طرق الاستخدام

### الطريقة 1: استخدام AppConfig مباشرة
```dart
import 'core/config/app_config.dart';

// للحصول على الرابط الأساسي
final baseUrl = AppConfig.API_BASE_URL;
// النتيجة: http://192.168.1.100:3000

// للحصول على رابط API الكامل
final apiUrl = AppConfig.API_URL;
// النتيجة: http://192.168.1.100:3000/api/v1

// بناء رابط مخصص
final url = AppConfig.buildUrl('/customers/123');
// النتيجة: http://192.168.1.100:3000/api/v1/customers/123
```

### الطريقة 2: استخدام ApiEndpoints
```dart
import 'core/constants/api_endpoints.dart';

// روابط جاهزة
final customersUrl = ApiEndpoints.customers;
final customerUrl = ApiEndpoints.customerById('123');
final plansUrl = ApiEndpoints.installmentPlansByCustomer('456');
```

## 🔄 أمثلة على IPs

| الجهاز | IP |
|--------|-----|
| لابتوب 1 (الأساسي) | `192.168.1.100` |
| لابتوب 2 | `192.168.1.101` |
| محاكي Android | `10.0.2.2` |
| localhost | `127.0.0.1` |
| إنتاج | `your-domain.com` |

## 🛠️ تصحيح الأخطاء

لطباعة إعدادات API:
```dart
AppConfig.printConfig();
```

الناتج:
```
🔧 AppConfig:
   API_IP: 192.168.1.100
   API_PORT: 3000
   API_BASE_URL: http://192.168.1.100:3000
   API_URL: http://192.168.1.100:3000/api/v1
   Supabase Mode: false
```
