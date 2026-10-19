import 'package:flutter/material.dart';
import '../branding/brand_widgets.dart';
import '../core/models.dart';

/// Photorealistic original food illustration assets shipped with the app.
/// Bundled assets need no network connection and cannot trigger extra downloads.
/// Do not show another recipe's photo as a fallback for an unmatched recipe.
class RecipePhoto extends StatelessWidget {
  const RecipePhoto({super.key, required this.recipe, this.height = 184, this.hero = false,
    this.borderRadius = 18});
  final Recipe recipe;
  final double height;
  final bool hero;
  final double borderRadius;

  static const picturedRecipes = <String>{
    'eg_koshari','eg_molokhia','eg_mahshi','eg_ful','eg_besbousa',
    'eg_macaroni_beshamel','eg_hawawshi','eg_mombar','eg_kofta_rice',
    'eg_tahini_salad','eg_salata_baladi','eg_cabbage_mahshi',
    'eg_kishk_egyptian','eg_baladi_bread','eg_lentil_soup',
    'sa_kabsa','sa_jareesh','sa_saleeg','sa_mutabbaq','sa_luqaimat',
    'sy_fatteh','sy_kibbeh','sy_muhammara','sy_shishbarak',
    'sy_hariseh','tr_menemen',
    'eg_dessert_rice_pudding','eg_dessert_qashtuta','eg_dessert_sweet_koshari',
    'eg_dessert_om_ali','eg_dessert_belila','eg_dessert_cassata',
    'eg_dessert_salankateeh','eg_dessert_loaa','eg_dessert_bamboza',
    'eg_dessert_cake','eg_dessert_crepe','eg_dessert_creme_brulee',
    'eg_dessert_sah_adah_ambo','eg_dessert_motakandera',
  };

  static String? assetFor(String id, {bool hero = false}) {
    if (!picturedRecipes.contains(id)) return null;
    if (id == 'eg_koshari' && hero) return 'assets/photos/eg_koshari_hero.webp';
    return 'assets/photos/$id.webp';
  }

  @override
  Widget build(BuildContext context) {
    final path = assetFor(recipe.id, hero: hero);
    final palette = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: path == null
          ? ColoredBox(color: palette.primaryContainer.withValues(alpha: .45),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(recipe.emoji, style: TextStyle(fontSize: height < 135 ? 32 : 48)),
                if (height >= 135) ...[
                  const SizedBox(height: 2),
                  Text('صورة الوصفة قريبًا', style: TextStyle(fontSize: 11,
                    color: palette.onSurfaceVariant)),
                ],
              ]))
          : Image.asset(path, fit: BoxFit.cover, filterQuality: FilterQuality.medium,
              semanticLabel: 'صورة توضيحية واقعية المظهر لطبق ${recipe.name}',
              errorBuilder: (_, __, ___) => ColoredBox(
                color: KitchenBrand.roseCream,
                child: Center(child: Text(recipe.emoji,
                  style: const TextStyle(fontSize: 55))))),
      ),
    );
  }
}