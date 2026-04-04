# حل مشكلة خط Cairo

## المشكلة
الخط لا يظهر لأن الملفات الحالية هي مجرد نصوص وليست ملفات خط حقيقية (.ttf)

## الحل

### الطريقة 1: تحميل يدوي (موصى به)
1. افتح المتصفح وذهب إلى: https://fonts.google.com/specimen/Cairo
2. اضغط على زر "Download family"
3. ستحصل على ملف ZIP باسم "Cairo-vX.XXX.zip"
4. استخرج الملفات من الـ ZIP
5. انسخ هذه الملفات إلى `assets/fonts/`:
   - `static/Cairo-Regular.ttf` → `assets/fonts/Cairo-Regular.ttf`
   - `static/Cairo-Bold.ttf` → `assets/fonts/Cairo-Bold.ttf`
   - `static/Cairo-Light.ttf` → `assets/fonts/Cairo-Light.ttf`

### الطريقة 2: استخدام PowerShell (للمستخدمين المتقدمين)
```powershell
# تحميل الخط
Invoke-WebRequest -Uri "https://fonts.google.com/download?family=Cairo" -OutFile "Cairo.zip"

# استخراج الملفات
Expand-Archive -Path "Cairo.zip" -DestinationPath ".\Cairo_temp"

# نسخ الملفات الصحيحة
Copy-Item ".\Cairo_temp\static\Cairo-Regular.ttf" "assets\fonts\"
Copy-Item ".\Cairo_temp\static\Cairo-Bold.ttf" "assets\fonts\"
Copy-Item ".\Cairo_temp\static\Cairo-Light.ttf" "assets\fonts\"

# تنظيف
Remove-Item "Cairo.zip"
Remove-Item ".\Cairo_temp" -Recurse -Force
```

### بعد تحميل الملفات
1. أزل التعليقات من `pubspec.yaml` (أعد تفعيل قسم fonts)
2. شغل `flutter pub get`
3. أعد تشغيل التطبيق

## ملاحظات
- التطبيق حالياً يستخدم الخط الافتراضي لأن ملفات الخط غير موجودة
- بمجرد تحميل الملفات الحقيقية، سيظهر خط Cairo بشكل صحيح
- تأكد من أن أسماء الملفات مطابقة تماماً للحساسية لحالة الأحرف
