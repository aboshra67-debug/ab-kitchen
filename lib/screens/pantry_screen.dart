import 'package:flutter/material.dart';
import '../core/kitchen_controller.dart';
import '../widgets/recipe_card.dart';

class PantryScreen extends StatefulWidget {
  const PantryScreen({super.key, required this.controller});
  final KitchenController controller;
  @override
  State<PantryScreen> createState() => _PantryScreenState();
}

class _PantryScreenState extends State<PantryScreen> {
  String search = '';
  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final all = c.recipes.expand((r) => r.ingredients.map((i) => i.name)).toSet().toList()..sort();
    return AnimatedBuilder(animation: c, builder: (context, _) {
      final options = all.where((i) => i.contains(search)).toList();
      final suggestions = c.suggestedFromPantry().where((r) => c.matchRatio(r) > 0).take(8).toList();
      return ListView(padding: const EdgeInsets.all(16), children: [
        const Text('إيه الموجود عندك؟ 🧺', style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900)),
        const SizedBox(height: 7),
        const Text('اختار مكونات البيت ونقترح عليك وصفات تقدر تبدأ فيها فورًا.'),
        const SizedBox(height: 14),
        TextField(onChanged: (v) => setState(() => search = v),
          decoration: InputDecoration(prefixIcon: const Icon(Icons.search), hintText: 'دور على مكوّن...',
          suffixText: '${c.pantry.length} موجود')),
        const SizedBox(height: 12),
        Material(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(18),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 290),
            child: options.isEmpty
            ? const Center(child: Padding(padding: EdgeInsets.all(22), child: Text('المكوّن مش موجود في فهرس الوصفات الحالية.')))
            : ListView.builder(shrinkWrap: true, itemCount: options.length, itemBuilder: (_, i) {
                final name = options[i];
                return CheckboxListTile(dense: true, value: c.pantry.contains(name),
                  title: Text(name), onChanged: (_) => c.togglePantry(name));
              }),
          ),
        ),
        const SizedBox(height: 24),
        Text('أكلات مناسبة لمكوناتك (${suggestions.length})',
          style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
        const SizedBox(height: 5),
        if (suggestions.isEmpty) const Card(child: Padding(padding: EdgeInsets.all(22),
          child: Text('حدد مكونات البيت أولًا لتظهر الوصفات المناسبة.'))),
        ...suggestions.map((r) {
          final available = r.ingredients.where((i) => c.pantry.contains(i.name)).length;
          return RecipeCard(recipe: r, controller: c,
            subtitle: '$available من ${r.ingredients.length} مكونات متوفرة • الناقص ${r.ingredients.length-available}');
        }),
      ]);
    });
  }
}