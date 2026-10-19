import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ab_kitchen/core/models.dart';
import 'package:ab_kitchen/core/dessert_toppings.dart';
import 'package:ab_kitchen/core/kitchen_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<List<Recipe>> getRecipes() async {
    final raw = await rootBundle.loadString('assets/data/recipes_ar.json');
    return (jsonDecode(raw) as List<dynamic>)
        .map((e) => Recipe.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  test('14 unique base families and nine reusable extras without variant duplication', () async {
    final recipes = await getRecipes();
    final families = recipes.where((r) => r.isDessertCatalogue).toList();
    expect(recipes.length, greaterThanOrEqualTo(44));
    expect(families.length, 14);
    expect(families.map((r) => r.id).toSet().length, 14);
    expect(DessertToppings.byId.length, 9);
    expect(recipes.where((r) => r.id == 'eg_besbousa').length, 1);
    for (final recipe in families) {
      expect(recipe.country, 'eg');
      expect(recipe.category, 'كتالوج الحلويات');
      expect(recipe.toppingIds.length, greaterThanOrEqualTo(4));
      for (final id in recipe.toppingIds) {
        expect(DessertToppings.byId.containsKey(id), true);
      }
    }
  });

  test('Rice pudding mango and cream add quantities only once, with base steps preserved', () async {
    final r = (await getRecipes()).firstWhere((x) => x.id == 'eg_dessert_rice_pudding');
    final base = DessertToppings.ingredientsFor(r, const []);
    final combo = DessertToppings.ingredientsFor(r, ['mango', 'cream', 'mango', 'bogus']);
    expect(combo.length, base.length + 2);
    expect(combo.singleWhere((i) => i.name == 'مانجو مكعبات').quantity, 220);
    expect(combo.singleWhere((i) => i.name == 'قشطة بلدي').quantity, 120);
    expect(DessertToppings.stepsFor(r, ['cream', 'mango']).length, r.steps.length + 2);
    expect(DessertToppings.stepsFor(r, []).length, r.steps.length);
    expect(DessertToppings.validChoices(r, ['bogus']), isEmpty);
  });

  test('Saved extras survive app restart, include correct shopping quantities and never clear original state', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final rice = (await getRecipes()).firstWhere((x) => x.id == 'eg_dessert_rice_pudding');
    final controller = KitchenController.open([rice], prefs);
    controller.toggleFavorite(rice.id);
    controller.togglePantry('أرز مصري');
    controller.setDessertToppings(rice, ['mango', 'cream', 'not-real']);
    expect(controller.toppingsFor(rice), ['cream', 'mango']);
    controller.addMissingRecipeToShopping(rice, 2, const {});
    expect(controller.shopping.where((x) => x.name == 'أرز مصري'), isEmpty);
    expect(controller.shopping.singleWhere((x) => x.name == 'مانجو مكعبات').quantity, 110);
    expect(controller.shopping.singleWhere((x) => x.name == 'قشطة بلدي').quantity, 60);
    await Future<void>.delayed(const Duration(milliseconds: 120));
    final restored = KitchenController.open([rice], prefs);
    expect(restored.toppingsFor(rice), ['cream', 'mango']);
    expect(restored.favorites, contains(rice.id));
    expect(restored.pantry, contains('أرز مصري'));
    expect(restored.shopping.singleWhere((x) => x.name == 'مانجو مكعبات').quantity, 110);
    restored.setDessertToppings(rice, []);
    expect(restored.toppingsFor(rice), isEmpty);
    expect(restored.shopping.singleWhere((x) => x.name == 'مانجو مكعبات').quantity, 110,
      reason: 'Changing topping preferences must not silently modify shopping history.');
  });
}