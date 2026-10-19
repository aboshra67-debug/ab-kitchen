import 'package:flutter/material.dart';
import '../core/models.dart';
import '../core/kitchen_controller.dart';
import '../screens/recipe_screen.dart';

class RecipeCard extends StatelessWidget {
  const RecipeCard({super.key, required this.recipe, required this.controller, this.subtitle});
  final Recipe recipe;
  final KitchenController controller;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 11),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => Navigator.push(context, MaterialPageRoute(
          builder: (_) => RecipeScreen(recipe: recipe, controller: controller))),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            Container(width: 76, height: 78,
              decoration: BoxDecoration(color: color.primaryContainer.withValues(alpha: .62), borderRadius: BorderRadius.circular(17)),
              alignment: Alignment.center, child: Text(recipe.emoji, style: const TextStyle(fontSize: 38))),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(recipe.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800), maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 5),
              Text(subtitle ?? '${countries[recipe.country]?.$2 ?? ''} ${countries[recipe.country]?.$1 ?? ''} • ${recipe.category}',
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: TextStyle(color: color.onSurfaceVariant, fontSize: 12)),
              const SizedBox(height: 5),
              Row(children: [const Icon(Icons.schedule, size: 14), const SizedBox(width: 3),
                Text('${recipe.minutes} دقيقة', style: const TextStyle(fontSize: 12)),
                const SizedBox(width: 9), Text(recipe.difficulty, style: const TextStyle(fontSize: 12))]),
            ])),
            IconButton(
              tooltip: controller.favorites.contains(recipe.id) ? 'إزالة من المفضلة' : 'إضافة للمفضلة',
              icon: Icon(controller.favorites.contains(recipe.id) ? Icons.favorite : Icons.favorite_border,
                color: controller.favorites.contains(recipe.id) ? Colors.redAccent : color.onSurfaceVariant),
              onPressed: () => controller.toggleFavorite(recipe.id)),
          ]),
        ),
      ),
    );
  }
}