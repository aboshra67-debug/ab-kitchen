import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ab_kitchen/main.dart';
import 'package:ab_kitchen/branding/brand_widgets.dart';
import 'package:ab_kitchen/core/models.dart';
import 'package:ab_kitchen/core/kitchen_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Main tabs open without throwing, including offline assistant', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final controller = KitchenController.open([
      Recipe.fromJson({
        'id': 'smoke', 'name': 'رز بسيط', 'country': 'eg',
        'category': 'غداء', 'emoji': '🍚', 'description': 'وصفة تجربة',
        'minutes': 10, 'difficulty': 'سهل', 'servings': 4,
        'ingredients': [{'name': 'أرز', 'quantity': 200, 'unit': 'جرام'}],
        'steps': [{'title': 'اغسل', 'body': 'اغسل الأرز', 'minutes': 1}],
        'tags': [],
      }),
    ], prefs);
    await tester.pumpWidget(ABKitchenApp(controller: controller));
    expect(find.text('كل مطابخ العالم في مطبخك ✨'), findsOneWidget);
    expect(find.byType(BrandLogo), findsWidgets); // Actual approved logo is bundled.

    await tester.tap(find.descendant(
      of: find.byType(NavigationBar), matching: find.byIcon(Icons.kitchen_outlined)));
    await tester.pumpAndSettle();
    expect(find.text('إيه الموجود عندك؟ 🧺'), findsOneWidget);

    await tester.tap(find.descendant(
      of: find.byType(NavigationBar), matching: find.byIcon(Icons.calendar_month_outlined)));
    await tester.pumpAndSettle();
    expect(find.text('خطة الأكل الأسبوعية 📅'), findsOneWidget);

    await tester.tap(find.descendant(
      of: find.byType(NavigationBar), matching: find.byIcon(Icons.shopping_basket_outlined)));
    await tester.pumpAndSettle();
    expect(find.text('قائمة المشتريات 🛒'), findsOneWidget);

    await tester.tap(find.descendant(
      of: find.byType(NavigationBar), matching: find.byIcon(Icons.auto_awesome_outlined)));
    await tester.pumpAndSettle();
    expect(find.text('مساعد الطبخ ✨'), findsOneWidget);
    expect(find.byType(BrandIntro), findsOneWidget);
  });
}