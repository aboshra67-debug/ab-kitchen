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
    'sa_kabsa','sa_jareesh','sa_saleeg','sa_mutabbaq','sa_luqaimat',
    'sy_fatteh','sy_kibbeh','sy_muhammara','sy_shishbarak',
    'sy_hariseh','tr_menemen',
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
                Text(recipe.emoji, style: const TextStyle(fontSize: 48)),
                const SizedBox(height: 2),
                Text('صورة الوصفة قريبًا', style: TextStyle(fontSize: 11,
                  color: palette.onSurfaceVariant)),
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