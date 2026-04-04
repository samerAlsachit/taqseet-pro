# خطوات التحميل اليدوي لخط Cairo

## الطريقة الموصى بها: التحميل اليدوي

### 1. تحميل الخط
1. افتح المتصفح وذهب إلى: https://fonts.google.com/specimen/Cairo
2. اضغط على زر "Download family" 
3. ستحصل على ملف ZIP باسم "Cairo-vX.XXX.zip"

### 2. استخراج الملفات
1. استخرج الملفات من الـ ZIP
2. ستجد مجلد "static" يحتوي على:
   - Cairo-Regular.ttf
   - Cairo-Bold.ttf
   - Cairo-Light.ttf
   - Cairo-SemiBold.ttf
   - Cairo-Black.ttf

### 3. نسخ الملفات
انسخ هذه الملفات إلى `assets/fonts/`:
```powershell
# استبدال الملفات الحالية بالملفات الحقيقية
Copy-Item ".\Cairo-vX.XXX\static\Cairo-Regular.ttf" "assets\fonts\" -Force
Copy-Item ".\Cairo-vX.XXX\static\Cairo-Bold.ttf" "assets\fonts\" -Force
Copy-Item ".\Cairo-vX.XXX\static\Cairo-Light.ttf" "assets\fonts\" -Force
```

### 4. التحقق من الملفات
تأكد من وجود هذه الملفات:
- `assets/fonts/Cairo-Regular.ttf`
- `assets/fonts/Cairo-Bold.ttf`
- `assets/fonts/Cairo-Light.ttf`

### 5. إعادة التشغيل
1. شغل `flutter pub get`
2. أعد تشغيل التطبيق
3. سيظهر خط Cairo بشكل صحيح

## PowerShell Script (للمستخدمين المتقدمين)
```powershell
# تحميل الخط
Invoke-WebRequest -Uri "https://fonts.google.com/download?family=Cairo" -OutFile "Cairo.zip"

# استخراج الملفات
Expand-Archive -Path "Cairo.zip" -DestinationPath ".\Cairo_temp" -Force

# نسخ الملفات الصحيحة
Copy-Item ".\Cairo_temp\static\Cairo-Regular.ttf" "assets\fonts\" -Force
Copy-Item ".\Cairo_temp\static\Cairo-Bold.ttf" "assets\fonts\" -Force
Copy-Item ".\Cairo_temp\static\Cairo-Light.ttf" "assets\fonts\" -Force

# تنظيف
Remove-Item "Cairo.zip" -Force
Remove-Item ".\Cairo_temp" -Recurse -Force

# تحديث Flutter
flutter pub get
```

## ملاحظات هامة
- التطبيق حالياً يستخدم ملفات placeholder
- بمجرد استبدال الملفات، سيظهر خط Cairo بشكل صحيح
- تأكد من أن أسماء الملفات مطابقة تماماً
- قد تحتاج إلى إعادة تشغيل التطبيق بعد تحميل الملفات
