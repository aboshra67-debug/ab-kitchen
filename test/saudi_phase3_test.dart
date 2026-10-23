import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ab_kitchen/data/recipe_repository.dart';
import 'package:ab_kitchen/widgets/recipe_photo.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('Saudi phase 3: exactly 20 unique halal recipes with own bundled images', () async {
    final recipes = await RecipeRepository.load();
    final raw = jsonDecode(await rootBundle.loadString('assets/data/saudi_phase3_recipes.json')) as List<dynamic>;
    expect(recipes.length, 208);
    expect(recipes.where((r) => r.country == 'sa').length, 65);
    expect(raw.length, 20);
    expect(recipes.map((r) => r.id).toSet().length, 208);
    expect(RecipePhoto.saudiPhase3Jpg.length, 20);
    expect(RecipePhoto.picturedRecipes.length, 207);
    final names = <String>{};
    for (final item in raw) {
      final data = item as Map<String, dynamic>;
      final id = data['id'] as String;
      expect(data['country'], 'sa');
      expect(names.add((data['name'] as String).trim()), isTrue);
      expect(RecipePhoto.assetFor(id), 'assets/photos/$id.jpg');
      final bytes = await rootBundle.load('assets/photos/$id.jpg');
      expect(bytes.lengthInBytes, greaterThan(20000));
      final b = bytes.buffer.asUint8List();
      expect(b[0], 0xff);
      expect(b[1], 0xd8);
      final match = recipes.singleWhere((r) => r.id == id);
      expect(match.steps.length, greaterThanOrEqualTo(4));
      expect(match.ingredients.length, greaterThanOrEqualTo(3));
    }
  });
}
