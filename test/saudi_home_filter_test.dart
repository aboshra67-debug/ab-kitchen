import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ab_kitchen/main.dart';
import 'package:ab_kitchen/core/models.dart';
import 'package:ab_kitchen/core/kitchen_controller.dart';

Recipe testRecipe(String id, String country, String name) => Recipe.fromJson({
  'id': id, 'name': name, 'country': country,
  'category': 'أطباق رئيسية', 'emoji': '🍽️',
  'description': 'اختبار القائمة', 'minutes': 30,
  'difficulty': 'سهل', 'servings': 4,
  'ingredients': [{'name': 'أرز', 'quantity': 200, 'unit': 'جرام'}],
  'steps': [
    {'title': 'التحضير', 'body': 'جهز المكونات', 'minutes': 5},
    {'title': 'الطبخ', 'body': 'اطبخ حتى النضج', 'minutes': 20},
    {'title': 'التقديم', 'body': 'قدم الطبق', 'minutes': 5},
  ],
  'tags': [],
});

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Saudi selection hides Egyptian shortcuts and filters recipes', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({});
    final control = KitchenController.open([
      testRecipe('sa_test_kabsa', 'sa', 'كبسة اختبار'),
      testRecipe('eg_test_koshari', 'eg', 'كشري اختبار'),
    ], await SharedPreferences.getInstance());
    await tester.pumpWidget(ABKitchenApp(controller: control));
    expect(find.text('المطبخ المصري'), findsOneWidget);
    expect(find.text('كتالوج الحلويات المصرية'), findsOneWidget);
    await tester.ensureVisible(find.text('🇸🇦 السعودية'));
    await tester.tap(find.text('🇸🇦 السعودية'));
    await tester.pumpAndSettle();
    expect(find.text('المطبخ السعودي 🇸🇦'), findsOneWidget);
    expect(find.text('المطبخ المصري'), findsNothing);
    expect(find.text('كتالوج الحلويات المصرية'), findsNothing);
    expect(find.text('الوصفات (1)'), findsOneWidget);
    expect(find.text('كبسة اختبار'), findsOneWidget);
    expect(find.text('كشري اختبار'), findsNothing);
  });
}
