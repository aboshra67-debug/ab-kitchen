import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ab_kitchen/widgets/recipe_photo.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('131 food photographs are bundled, mapped to their own recipe and offline', () async {
    final data = jsonDecode(await rootBundle.loadString('assets/data/recipes_ar.json'))
        as List<dynamic>;
    final ids = data.map((entry) => (entry as Map<String, dynamic>)['id'] as String).toSet();
    expect(ids.length, 148);
    expect(RecipePhoto.picturedRecipes.length, 131);
    expect(RecipePhoto.picturedRecipes.difference(ids), isEmpty);

    for (final id in RecipePhoto.picturedRecipes) {
      final path = RecipePhoto.assetFor(id);
      expect(path, 'assets/photos/$id.webp', reason: 'Wrong recipe image for $id');
      final img = await rootBundle.load(path!);
      expect(img.lengthInBytes, greaterThan(3000),
          reason: 'Missing or suspiciously small offline photo: $id');
    }
    expect(RecipePhoto.assetFor('eg_koshari', hero: true),
        'assets/photos/eg_koshari_hero.webp');
    final originalHero = await rootBundle.load('assets/photos/eg_koshari_hero.webp');
    expect(originalHero.lengthInBytes, greaterThan(3000));

    final missing = ids.difference(RecipePhoto.picturedRecipes);
    expect(missing.length, 17);
    expect(missing, contains('eg_fino_bread')); // Earlier offline JPEG not in source GitHub yet.
    for (final id in missing) {
      expect(RecipePhoto.assetFor(id), isNull);
    }
  });
}
