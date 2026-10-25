import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ab_kitchen/data/recipe_repository.dart';
import 'package:ab_kitchen/widgets/recipe_photo.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('Saudi phase 2 has 20 distinct recipes and individual offline JPEGs', () async {
    final recipes = await RecipeRepository.load();
    final raw = jsonDecode(await rootBundle.loadString('assets/data/saudi_phase2_recipes.json')) as List<dynamic>;
    expect(recipes.length, 248);
    expect(recipes.where((r) => r.country == 'sa').length, 65);
    expect(raw.length, 20);
    expect(RecipePhoto.saudiPhase2Jpg.length, 20);
    expect(RecipePhoto.picturedRecipes.length, 248);
    final names = <String>{};
    for (final item in raw) {
      final data = item as Map<String, dynamic>;
      final id = data['id'] as String;
      expect(data['country'], 'sa');
      expect(names.add(data['name'] as String), isTrue);
      expect(RecipePhoto.assetFor(id), 'assets/photos/$id.jpg');
      final bytes = await rootBundle.load('assets/photos/$id.jpg');
      expect(bytes.lengthInBytes, greaterThan(20000));
      final b = bytes.buffer.asUint8List();
      expect(b[0], 0xff);
      expect(b[1], 0xd8);
      final row = recipes.singleWhere((r) => r.id == id);
      expect(row.steps.length, greaterThanOrEqualTo(4));
    }
  });
}
