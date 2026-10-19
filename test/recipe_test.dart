import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ab_kitchen/core/models.dart';
import 'package:ab_kitchen/core/kitchen_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Arabic recipe asset has unique IDs, safe ingredient quantities, and steps', () async {
    final content = await rootBundle.loadString('assets/data/recipes_ar.json');
    final rows = jsonDecode(content) as List<dynamic>;
    final recipes = rows.map((e) => Recipe.fromJson(e as Map<String, dynamic>)).toList();
    expect(recipes.length, greaterThanOrEqualTo(30));
    expect(recipes.map((e) => e.id).toSet().length, recipes.length);
    expect(recipes.map((e) => e.country).toSet(), containsAll(['eg', 'sa', 'sy']));
    for (final r in recipes) {
      expect(r.servings, greaterThan(0));
      expect(r.ingredients, isNotEmpty);
      expect(r.steps.length, greaterThanOrEqualTo(3));
      for (final ingredient in r.ingredients) { expect(ingredient.quantity, greaterThan(0)); }
    }
  });

  test('Serving quantities scale consistently', () {
    const ingredient = Ingredient(name: 'أرز', quantity: 400, unit: 'جرام');
    expect(ingredient.forServings(2, 4), 200);
    expect(ingredient.forServings(6, 4), 600);
  });

  test('Shopping aggregates same ingredient and saves user choices', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final controller = KitchenController.open(const [], prefs);
    controller.addManualItem('أرز', 200, 'جرام');
    controller.addManualItem('أرز', 250, 'جرام');
    controller.togglePantry('طماطم');
    controller.toggleFavorite('eg_koshari');
    expect(controller.shopping.length, 1);
    expect(controller.shopping.single.quantity, 450);
    await Future<void>.delayed(const Duration(milliseconds: 100));
    final reloaded = KitchenController.open(const [], prefs);
    expect(reloaded.shopping.single.quantity, 450);
    expect(reloaded.pantry, contains('طماطم'));
    expect(reloaded.favorites, contains('eg_koshari'));
  });

  test('Missing-only shopping respects checked and pantry items', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final recipe = Recipe.fromJson({
      'id': 'shopping_check', 'name': 'تجربة', 'country': 'eg',
      'category': 'غداء', 'emoji': '🍚', 'description': 'اختبار',
      'minutes': 15, 'difficulty': 'سهل', 'servings': 4,
      'ingredients': [
        {'name': 'أرز', 'quantity': 400, 'unit': 'جرام'},
        {'name': 'طماطم', 'quantity': 2, 'unit': 'حبة'},
        {'name': 'بصل', 'quantity': 2, 'unit': 'حبة'},
      ],
      'steps': [{'title': 'ابدأ', 'body': 'حضّر', 'minutes': 0}],
      'tags': [],
    });
    final controller = KitchenController.open([recipe], prefs);
    controller.togglePantry('طماطم');
    controller.addMissingRecipeToShopping(recipe, 2, {2});
    expect(controller.shopping.length, 1);
    expect(controller.shopping.single.name, 'أرز');
    expect(controller.shopping.single.quantity, 200);
    controller.addMissingRecipeToShopping(recipe, 2, {2});
    expect(controller.shopping.single.quantity, 400);
    // Removing saved checked items remains an explicit operation.
    controller.setItemChecked(controller.shopping.single, true);
    controller.removeCheckedItems();
    expect(controller.shopping, isEmpty);
  });

  test('Invalid manual quantities never enter persisted state', () async {
    SharedPreferences.setMockInitialValues({});
    final controller = KitchenController.open(
      const [], await SharedPreferences.getInstance());
    controller.addManualItem('زيت', double.infinity, 'مل');
    controller.addManualItem('زيت', double.nan, 'مل');
    controller.addManualItem('زيت', -1, 'مل');
    expect(controller.shopping, isEmpty);
  });

  test('Planner only accepts known recipes and valid days', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final recipe = Recipe.fromJson({
      'id':'known','name':'وصفة','country':'eg','category':'إفطار',
      'emoji':'🍚','description':'تجربة','minutes':15,
      'difficulty':'سهل','servings':4,'ingredients':[{'name':'أرز','quantity':100,'unit':'جرام'}],
      'steps':[{'title':'تجربة','body':'خطوة','minutes':1}], 'tags':[]
    });
    final controller = KitchenController.open([recipe], prefs);
    controller.setPlannedMeal(0, 0, 'fake');
    controller.setPlannedMeal(10, 0, 'known');
    expect(controller.plannedMeals, isEmpty);
    controller.setPlannedMeal(0, 0, 'known');
    expect(controller.plannedMeals['0:0'], 'known');
  });
}

// Tests for batch add and the non-finite number guard. These stay independent
// from Flutter widgets so they can run on both Linux and macOS runners.