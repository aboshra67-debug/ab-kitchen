import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ab_kitchen/data/recipe_repository.dart';
import 'package:ab_kitchen/widgets/recipe_photo.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('Syrian phase 3: 20 new unique halal recipes and distinct offline JPEG photos', () async {
    final recipes=await RecipeRepository.load();
    expect(recipes.length,268);
    expect(recipes.map((r)=>r.id).toSet().length,268);
    expect(recipes.where((r)=>r.country=='sy').length,65);
    expect(recipes.where((r)=>r.country=='sa').length,65);
    expect(RecipePhoto.picturedRecipes.length,268);
    expect(RecipePhoto.syrianPhase1Jpg.length,20);
    expect(RecipePhoto.syrianPhase2Jpg.length,20);
    expect(RecipePhoto.syrianPhase3Jpg.length,20);
    final raw=jsonDecode(await rootBundle.loadString('assets/data/syrian_phase3_recipes.json')) as List<dynamic>;
    expect(raw.length,20);
    final names=<String>{};final pics=<List<int>>[];
    for (final item in raw) {
      final x=item as Map<String,dynamic>;
      final id=x['id'] as String;
      expect(id,startsWith('sy_'));
      expect(x['country'],'sy');
      expect(names.add((x['name'] as String).trim()),isTrue);
      expect((x['ingredients'] as List).length,greaterThanOrEqualTo(6));
      expect((x['steps'] as List).length,greaterThanOrEqualTo(4));
      for (final e in x['ingredients'] as List) {
        final i=e as Map<String,dynamic>;
        expect(i['quantity'] as num,greaterThan(0));
        expect((i['name'] as String).trim(),isNotEmpty);
        expect(RegExp('خنزير|نبيذ|كحول|خمور').hasMatch(i['name'] as String),isFalse);
      }
      expect(RecipePhoto.assetFor(id),'assets/photos/$id.jpg');
      final bytes=(await rootBundle.load('assets/photos/$id.jpg')).buffer.asUint8List();
      expect(bytes.length,greaterThan(30000));
      expect(bytes.take(3).toList(),<int>[255,216,255]);
      expect(bytes[bytes.length-2],255);
      expect(bytes[bytes.length-1],217);
      for(final pic in pics){expect(listEquals(bytes,pic),isFalse,reason:'Duplicate image for $id');}
      pics.add(bytes);
    }
    expect(RecipePhoto.syrianPhase3Jpg.intersection(RecipePhoto.syrianPhase1Jpg),isEmpty);
    expect(RecipePhoto.syrianPhase3Jpg.intersection(RecipePhoto.syrianPhase2Jpg),isEmpty);
  });
}
