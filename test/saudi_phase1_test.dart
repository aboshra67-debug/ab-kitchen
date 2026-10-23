import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ab_kitchen/widgets/recipe_photo.dart';
import 'package:ab_kitchen/data/recipe_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('Saudi phase 1 adds exactly 20 regional, distinct, offline pictured dishes', () async {
    final recipes = await RecipeRepository.load();
    final audit = (jsonDecode(await rootBundle.loadString('assets/data/saudi_phase1_photo_audit.json')) as List<dynamic>);
    expect(recipes.length, 208);
    expect(recipes.where((r) => r.country == 'sa').length, 65);
    expect(audit.length, 20);
    expect(RecipePhoto.picturedRecipes.length, 207);
    final unique = <String>{};
    for (final a in audit) {
      final id = a['recipe_id'] as String;
      expect(unique.add(id), isTrue);
      expect(RecipePhoto.assetFor(id), 'assets/photos/$id.webp');
      final bytes = await rootBundle.load('assets/photos/$id.webp');
      expect(bytes.lengthInBytes, greaterThan(10000));
      final row = recipes.singleWhere((r) => r.id == id);
      expect(row.country, 'sa');
      expect(row.steps.length, greaterThanOrEqualTo(3));
    }
  });
}
