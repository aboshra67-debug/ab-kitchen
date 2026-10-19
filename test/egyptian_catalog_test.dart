import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ab_kitchen/core/models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('Egyptian collection contains 123 unique dishes with 11 subcategories', () async {
    final decoded = jsonDecode(await rootBundle.loadString('assets/data/recipes_ar.json')) as List<dynamic>;
    final recipes = decoded.map((row) => Recipe.fromJson(row as Map<String, dynamic>)).toList();
    expect(recipes.length, 148);
    final egypt = recipes.where((r) => r.country == 'eg').toList();
    expect(egypt.length, 123);
    expect(egypt.map((r) => r.id).toSet().length, 123);
    expect(egypt.map((r) => r.name.trim()).toSet().length, 123);
    expect(egypt.map((r) => r.category).toSet().length, 11);
    expect(egypt.where((r) => r.isDessertCatalogue).length, 14);
    expect(egypt.where((r) => r.category == 'أسماك ومأكولات بحرية').length, 11);
    expect(egypt.where((r) => r.category == 'مخبوزات ومعجنات').length, 6);
    expect(egypt.every((r) => r.steps.length >= 3 && r.ingredients.isNotEmpty), isTrue);
  });
  test('Previously delivered Egyptian dishes retain stable IDs and independent dessert extras', () async {
    final decoded = jsonDecode(await rootBundle.loadString('assets/data/recipes_ar.json')) as List<dynamic>;
    final recipes = decoded.map((row) => Recipe.fromJson(row as Map<String, dynamic>)).toList();
    for (final id in ['eg_koshari', 'eg_molokhia', 'eg_mahshi', 'eg_ful', 'eg_besbousa',
      'eg_dessert_rice_pudding', 'eg_dessert_qashtuta']) {
      expect(recipes.where((r) => r.id == id).length, 1);
    }
    expect(recipes.singleWhere((r) => r.id == 'eg_dessert_rice_pudding').toppingIds.length,
      greaterThan(4));
  });
}