import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ab_kitchen/widgets/recipe_photo.dart';
import 'package:ab_kitchen/data/recipe_repository.dart';

/// V0.7.10: visual identity checks for eleven replacement Saudi food assets.
/// These are structural regression checks, not a substitute for manual visual QA.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const ids = <String>[
    'sa_mathaan_bread',
    'sa_harees',
    'sa_mandi_lamb',
    'sa_timman_hail',
    'sa_mansaf_tabuk',
    'sa_muhammar_barnyush',
    'sa_matban_fish',
    'sa_khumayah_north',
    'sa_mahmousa_north',
    'sa_thareed_lamb',
    'sa_muaraq_madinah',
  ];
  test('Eleven Saudi corrections are unique standalone offline JPEGs', () async {
    final recipes = await RecipeRepository.load();
    expect(recipes.length, 268);
    expect(recipes.where((r) => r.country == 'sa').length, 65);
    final allImages = <Uint8List>[];
    for (final id in ids) {
      expect(recipes.any((r) => r.id == id && r.country == 'sa'), isTrue);
      final path = 'assets/photos/$id.jpg';
      expect(RecipePhoto.assetFor(id), path);
      final bytes = (await rootBundle.load(path)).buffer.asUint8List();
      expect(bytes.length, greaterThan(50000));
      expect(bytes.take(3).toList(), <int>[0xff, 0xd8, 0xff]);
      expect(bytes[bytes.length - 2], 0xff);
      expect(bytes[bytes.length - 1], 0xd9);
      for (final other in allImages) {
        expect(listEquals(bytes, other), isFalse,
          reason: 'Different food names must not share identical picture data: $id');
      }
      allImages.add(bytes);
    }
  });
}
