import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ab_kitchen/core/kitchen_controller.dart';
import 'package:ab_kitchen/data/recipe_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('existing ab_kitchen_v1 state is preserved across an app upgrade', () async {
    final original = jsonEncode({
      'favorites': ['eg_koshari'],
      'pantry': ['أرز'],
      'shopping': [],
      'plannedMeals': {},
      'cookingProgress': {},
      'dessertSelections': {},
      'darkMode': true,
      'defaultServings': 5,
    });
    SharedPreferences.setMockInitialValues({'ab_kitchen_v1': original});
    final prefs = await SharedPreferences.getInstance();
    final controller = KitchenController.open(await RecipeRepository.load(), prefs);
    expect(controller.recipes.length, 248);
    expect(controller.hasStorageError, isFalse);
    expect(controller.favorites, contains('eg_koshari'));
    expect(controller.pantry, contains('أرز'));
    expect(controller.darkMode, isTrue);
    expect(controller.defaultServings, 5);
    expect(prefs.getString('ab_kitchen_v1'), original);

    controller.setDefaultServings(6);
    final saved = jsonDecode(prefs.getString('ab_kitchen_v1')!) as Map<String, dynamic>;
    expect(saved['favorites'], contains('eg_koshari'));
    expect(saved['pantry'], contains('أرز'));
    expect(saved['darkMode'], isTrue);
    expect(saved['defaultServings'], 6);
  });

  test('malformed stored state is not overwritten automatically', () async {
    const original = '{corrupt_unparseable_user_data';
    SharedPreferences.setMockInitialValues({'ab_kitchen_v1': original});
    final prefs = await SharedPreferences.getInstance();
    final controller = KitchenController.open(await RecipeRepository.load(), prefs);
    expect(controller.hasStorageError, isTrue);
    controller.setDarkMode(true);
    expect(prefs.getString('ab_kitchen_v1'), original);
  });
}
