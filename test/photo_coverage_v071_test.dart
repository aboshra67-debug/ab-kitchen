import 'package:flutter/services.dart';
import 'package:ab_kitchen/data/recipe_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ab_kitchen/widgets/recipe_photo.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('228 food images are bundled, mapped to their own recipe and offline', () async {
    final recipes = await RecipeRepository.load();
    final ids = recipes.map((entry) => entry.id).toSet();
    expect(ids.length, 228);
    expect(RecipePhoto.picturedRecipes.length, 228);
    expect(RecipePhoto.picturedRecipes.difference(ids), isEmpty);

    for (final id in RecipePhoto.picturedRecipes) {
      final path = RecipePhoto.assetFor(id);
      expect(path, (id == 'eg_fino_bread' || RecipePhoto.saudiPhase2JpegIds.contains(id) || RecipePhoto.saudiPhase3Jpg.contains(id) || RecipePhoto.syrianPhase1Jpg.contains(id)) ? 'assets/photos/$id.jpg' : 'assets/photos/$id.webp', reason: 'Wrong recipe image for $id');
      final img = await rootBundle.load(path!);
      expect(img.lengthInBytes, greaterThan(3000),
          reason: 'Missing or suspiciously small offline photo: $id');
    }
    expect(RecipePhoto.assetFor('eg_koshari', hero: true),
        'assets/photos/eg_koshari_hero.webp');
    final originalHero = await rootBundle.load('assets/photos/eg_koshari_hero.webp');
    expect(originalHero.lengthInBytes, greaterThan(3000));

    final missing = ids.difference(RecipePhoto.picturedRecipes);
    expect(missing, isEmpty);
    for (final id in missing) {
      expect(RecipePhoto.assetFor(id), isNull);
    }
  });
}
