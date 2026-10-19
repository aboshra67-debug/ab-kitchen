# AB Kitchen V0.2 — سجل Safe Patch

الأساس: AB_Kitchen_Flutter_V0_1_SAFE_SOURCE.zip (لم نعدل النسخة الأصلية؛ أُنشئت نسخة جديدة فقط).

## ملفات معدلة
- `lib/core/kitchen_controller.dart`: إضافة `addMissingRecipeToShopping` ذات عملية حفظ واحدة؛ تجاهل كميات المشتريات اليدوية غير المنتهية وغير الصالحة.
- `lib/screens/recipe_screen.dart`: وصل إضافة المشتريات بالطريقة المجمعة؛ استبدال عدّاد يعتمد على عدد ticks بموعد نهائي قائم على ساعة الجهاز؛ تحديثه عند عودة التطبيق؛ منع overflow بتخطيط قابل للتمرير.
- `lib/screens/pantry_screen.dart`: حذف استيراد غير مستخدم فقط.
- `lib/screens/settings_screen.dart`: تحديث تسمية رقم الإصدار المعروض فقط.
- `pubspec.yaml`: رفع الإصدار إلى 0.2.0+2 دون تغيير dependencies.
- `.github/workflows/flutter_ci.yml`: تهيئة منفصلة لمشروعي Android وiOS، تحليل واختبارات في كل منصة، APK تجريبي يرفع فقط عند نجاح جميع مراحل Android.
- `test/recipe_test.dart`: اختبارات إضافية لحفظ المشتريات ومكونات الثلاجة والقيم غير الصالحة.

## ملفات مضافة
- `test/smoke_widget_test.dart`: اختبار بسيط لفتح الموديولات الرئيسية.
- `tools/verify_and_build.sh`: تشغيل التحقق والبناء على جهاز يحتوي Flutter SDK.
- `CI_BUILD_INSTRUCTIONS.md`، `V0_2_SAFE_PATCH.md`: توثيق خطوات البناء وبيان الحدود الفعلية.

## بدون حذف
- لم نحذف وصفة، جدولًا، موديولًا، ملف تخزين، أو وظيفة من مشروع V0.1.
- لم يُنشأ أو يُعدّل أي مستودع GitHub قائم، ولم تُنشأ ملفات توقيع.
- لم يتم ادعاء نجاح اختبار Dart/Flutter بدون SDK، ولا بنـاء APK/iOS.