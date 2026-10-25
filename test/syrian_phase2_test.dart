import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ab_kitchen/data/recipe_repository.dart';
import 'package:ab_kitchen/widgets/recipe_photo.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('Syria phase2 adds 20 verified entries and distinct bundled JPEGs', () async {
    final recipes = await RecipeRepository.load();
    expect(recipes.length, 268);
    expect(recipes.map((r) => r.id).toSet().length, 268);
    expect(recipes.where((r) => r.country == 'sy').length, 65);
    expect(recipes.where((r) => r.country == 'sa').length, 65);
    expect(RecipePhoto.picturedRecipes.length, 268);
    expect(RecipePhoto.syrianPhase1Jpg.length, 20);
    expect(RecipePhoto.syrianPhase2Jpg.length, 20);
    final raw = jsonDecode(await rootBundle.loadString('assets/data/syrian_phase2_recipes.json')) as List<dynamic>;
    expect(raw.length, 20);
    final names = <String>{};
    final pictures = <List<int>>[];
    for (final item in raw) {
      final recipe = item as Map<String,dynamic>;
      final id = recipe['id'] as String;
      expect(id, startsWith('sy_'));
      expect(recipe['country'], 'sy');
      expect(names.add((recipe['name'] as String).trim()), isTrue);
      expect((recipe['ingredients'] as List).length, greaterThanOrEqualTo(5));
      expect((recipe['steps'] as List).length, greaterThanOrEqualTo(4));
      for (final entry in recipe['ingredients'] as List) {
        final ing = entry as Map<String,dynamic>;
        expect(ing['quantity'] as num, greaterThan(0));
        expect((ing['name'] as String).trim().isNotEmpty, isTrue);
        expect(RegExp('خنزير|كحول|نبيذ|خمور').hasMatch(ing['name'] as String), isFalse);
      }
      expect(RecipePhoto.assetFor(id),'assets/photos/$id.jpg');
      final data=(await rootBundle.load('assets/photos/$id.jpg')).buffer.asUint8List();
      expect(data.length,greaterThan(30000));
      expect(data.take(3).toList(),<int>[255,216,255]);
      expect(data[data.length-2],255);
      expect(data[data.length-1],217);
      for (final old in pictures) {
        expect(listEquals(data,old), isFalse,reason:'Duplicated JPEG: $id');
      }
      pictures.add(data);
    }
    expect(RecipePhoto.syrianPhase1Jpg.intersection(RecipePhoto.syrianPhase2Jpg),isEmpty);
  });
}
