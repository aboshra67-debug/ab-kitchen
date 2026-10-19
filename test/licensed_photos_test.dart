import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ab_kitchen/widgets/recipe_photo.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('Every approved Egyptian photo is bundled, licensed and bound to existing recipe', () async {
    final credits = (jsonDecode(await rootBundle.loadString('assets/data/licensed_photo_credits.json')) as List<dynamic>).cast<Map<String, dynamic>>();
    final recipes = (jsonDecode(await rootBundle.loadString('assets/data/recipes_ar.json')) as List<dynamic>).cast<Map<String, dynamic>>();
    final ids = recipes.map((x) => x['id']).toSet();
    expect(credits.length, 10);
    for (final credit in credits) {
      final id = credit['recipe_id'] as String;
      expect(ids.contains(id), isTrue);
      expect(RecipePhoto.assetFor(id), 'assets/photos/$id.webp');
      expect((credit['author'] as String).isNotEmpty, isTrue);
      expect((credit['license'] as String).isNotEmpty, isTrue);
      expect((credit['source_file_page'] as String).startsWith('https://commons.wikimedia.org/wiki/File:'), isTrue);
      final bytes = await rootBundle.load('assets/photos/$id.webp');
      expect(bytes.lengthInBytes, greaterThan(3000));
    }
  });
}