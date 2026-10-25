import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ab_kitchen/widgets/recipe_photo.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('All sixteen new Egyptian images are matched, unique, and offline', () async {
    final photos = (jsonDecode(await rootBundle.loadString(
      'assets/data/generated_photo_audit_v074.json')) as List<dynamic>);
    final recipes = (jsonDecode(await rootBundle.loadString(
      'assets/data/recipes_ar.json')) as List<dynamic>);
    final ids = recipes.map((x) => (x as Map<String, dynamic>)['id']).toSet();
    expect(recipes.length, 148);
    expect(photos.length, 16);
    expect(RecipePhoto.picturedRecipes.length, 248);
    expect(RecipePhoto.assetFor('eg_duqqa_alex'),
      'assets/photos/eg_duqqa_alex.webp');
    final signatures = <String>{};
    for (final row in photos) {
      final item = row as Map<String, dynamic>;
      final id = item['recipe_id'] as String;
      expect(ids, contains(id));
      expect(RecipePhoto.assetFor(id), 'assets/photos/$id.webp');
      final bytes = await rootBundle.load('assets/photos/$id.webp');
      expect(bytes.lengthInBytes, greaterThan(5000));
      signatures.add(bytes.buffer.asUint8List().take(256).join(','));
    }
    expect(signatures.length, photos.length);
    expect(RecipePhoto.assetFor('eg_fino_bread'), 'assets/photos/eg_fino_bread.jpg');
    expect((await rootBundle.load('assets/photos/eg_fino_bread.jpg')).lengthInBytes, greaterThan(10000));
  });
}
