import 'package:flutter/material.dart';
import '../core/models.dart';
import '../core/kitchen_controller.dart';
import '../screens/recipe_screen.dart';
import 'recipe_photo.dart';
import '../branding/brand_widgets.dart';

class RecipeCard extends StatelessWidget {
  const RecipeCard({super.key, required this.recipe, required this.controller, this.subtitle});
  final Recipe recipe;
  final KitchenController controller;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(borderRadius: BorderRadius.circular(20),
        onTap: () => Navigator.push(context, MaterialPageRoute(
          builder: (_) => RecipeScreen(recipe: recipe, controller: controller))),
        child: Padding(padding: const EdgeInsets.all(10), child: Row(children: [
          SizedBox(width: 116, child: RecipePhoto(recipe: recipe, height: 112, borderRadius: 15)),
          const SizedBox(width: 11),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(recipe.name, maxLines: 2, overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            Text(subtitle ?? '${countries[recipe.country]?.$2 ?? ''} ${countries[recipe.country]?.$1 ?? ''} • ${recipe.category}',
              maxLines: 1, overflow: TextOverflow.ellipsis,
              style: TextStyle(color: colors.onSurfaceVariant, fontSize: 11)),
            const SizedBox(height: 8),
            Row(children: [Icon(Icons.schedule_outlined, size: 15, color: colors.primary),
              const SizedBox(width: 4), Text('${recipe.minutes} دقيقة', style: const TextStyle(fontSize: 12)),
              const Spacer(), Text(recipe.difficulty, style: const TextStyle(fontSize: 11))]),
            const SizedBox(height: 5),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              Text('عرض الوصفة', style: TextStyle(fontWeight: FontWeight.bold, color: colors.primary, fontSize: 12)),
              Icon(Icons.arrow_back_ios_new, size: 12, color: colors.primary),
            ]),
          ])),
          IconButton(
            tooltip: controller.favorites.contains(recipe.id) ? 'إزالة من المفضلة' : 'إضافة للمفضلة',
            icon: Icon(controller.favorites.contains(recipe.id) ? Icons.favorite : Icons.favorite_border,
              color: controller.favorites.contains(recipe.id) ? KitchenBrand.tomato : colors.onSurfaceVariant),
            onPressed: () => controller.toggleFavorite(recipe.id)),
        ])),
      ));
  }
}