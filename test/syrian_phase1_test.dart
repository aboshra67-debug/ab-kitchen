import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ab_kitchen/data/recipe_repository.dart';
import 'package:ab_kitchen/widgets/recipe_photo.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('Syrian phase 1 contains 20 unique halal recipes with separate offline JPEGs', () async {
    final recipes = await RecipeRepository.load();
    final raw = jsonDecode(await rootBundle.loadString('assets/data/syrian_phase1_recipes.json')) as List<dynamic>;
    expect(recipes.length, 268);
    expect(recipes.where((r) => r.country == 'sy').length, 65);
    expect(recipes.where((r) => r.country == 'sa').length, 65);
    expect(recipes.map((r) => r.id).toSet().length, 268);
    expect(raw.length, 20);
    expect(RecipePhoto.syrianPhase1Jpg.length, 20);
    expect(RecipePhoto.picturedRecipes.length, 268);
    final names = <String>{};
    final photoData = <List<int>>[];
    for (final item in raw) {
      final row = item as Map<String, dynamic>;
      final id = row['id'] as String;
      expect(id, startsWith('sy_'));
      expect(row['country'], 'sy');
      expect(names.add(row['name'] as String), isTrue);
      expect((row['ingredients'] as List).length, greaterThanOrEqualTo(5));
      expect((row['steps'] as List).length, greaterThanOrEqualTo(4));
      for (final entry in row['ingredients'] as List) {
        final ingredient = entry as Map<String, dynamic>;
        expect((ingredient['quantity'] as num), greaterThan(0));
        final lower = (ingredient['name'] as String).toLowerCase();
        expect(lower.contains('خنزير') || lower.contains('نبيذ') || lower.contains('كحول'), isFalse);
      }
      expect(RecipePhoto.assetFor(id), 'assets/photos/$id.jpg');
      final bytes = (await rootBundle.load('assets/photos/$id.jpg')).buffer.asUint8List();
      expect(bytes.length, greaterThan(25000));
      expect(bytes.take(3).toList(), <int>[255,216,255]);
      for (final other in photoData) {
        expect(listEquals(bytes, other), isFalse, reason:'Duplicate image data: $id');
      }
      photoData.add(bytes);
    }
  });
  test('Saudi sago has a replacement standalone image', () async {
    expect(RecipePhoto.assetFor('sa_sago'), 'assets/photos/sa_sago.jpg');
    final bytes = (await rootBundle.load('assets/photos/sa_sago.jpg')).buffer.asUint8List();
    expect(bytes.length, greaterThan(60000));
    expect(bytes.take(3).toList(), <int>[255,216,255]);
  });
}
