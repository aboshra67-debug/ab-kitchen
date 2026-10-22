import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ab_kitchen/data/recipe_repository.dart';
import 'package:ab_kitchen/widgets/recipe_photo.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('V077 loads 188 recipes, 45 Saudi, 20 new matched offline photos', () async {
    final all = await RecipeRepository.load();
    final base = jsonDecode(await rootBundle.loadString('assets/data/recipes_ar.json')) as List<dynamic>;
    final one = jsonDecode(await rootBundle.loadString('assets/data/saudi_phase1_recipes.json')) as List<dynamic>;
    final two = jsonDecode(await rootBundle.loadString('assets/data/saudi_phase2_recipes.json')) as List<dynamic>;
    expect(base.length, 148);
    expect(one.length, 20);
    expect(two.length, 20);
    expect(all.length, 188);
    expect(all.map((r) => r.id).toSet().length, 188);
    expect(all.where((r) => r.country == 'sa').length, 45);
    expect(RecipePhoto.picturedRecipes.length, 187);
    for (final raw in two) {
      final row = raw as Map<String, dynamic>;
      final id = row['id'] as String;
      final path = RecipePhoto.assetFor(id);
      expect(path, isNotNull);
      expect(path!.endsWith(RecipePhoto.saudiPhase2JpegIds.contains(id) ? '.jpg' : '.webp'), isTrue);
      final bytes = await rootBundle.load(path);
      expect(bytes.lengthInBytes, greaterThan(3000));
      final recipe = all.singleWhere((r) => r.id == id);
      expect(recipe.ingredients, isNotEmpty);
      expect(recipe.steps.length, greaterThanOrEqualTo(3));
    }
  });
}
