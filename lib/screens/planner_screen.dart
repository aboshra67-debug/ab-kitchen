import 'package:flutter/material.dart';
import '../core/kitchen_controller.dart';
import '../core/models.dart';
import '../branding/brand_widgets.dart';

class PlannerScreen extends StatelessWidget {
  const PlannerScreen({super.key, required this.controller});
  final KitchenController controller;

  Future<void> _choose(BuildContext context, int day, int meal) async {
    final selected = await showModalBottomSheet<String>(context: context, isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => SafeArea(child: FractionallySizedBox(heightFactor: .8,
        child: Column(children: [
          Padding(padding: const EdgeInsets.all(16), child: Text('اختار وصفة: ${weekDays[day]} / ${mealNames[meal]}',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17))),
          ListTile(leading: const Icon(Icons.delete_outline), title: const Text('إزالة الوجبة'),
            onTap: () => Navigator.pop(ctx, '__remove__')),
          Expanded(child: ListView.builder(itemCount: controller.recipes.length, itemBuilder: (_, i) {
            final r = controller.recipes[i];
            return ListTile(leading: Text(r.emoji, style: const TextStyle(fontSize: 26)),
              title: Text(r.name), subtitle: Text('${r.minutes} دقيقة • ${r.category}'),
              onTap: () => Navigator.pop(ctx, r.id));
          })),
        ]))));
    if (selected != null) controller.setPlannedMeal(day, meal, selected == '__remove__' ? null : selected);
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(animation: controller, builder: (context, _) {
    final occupied = controller.plannedMeals.length;
    return ListView(padding: const EdgeInsets.all(16), children: [
      BrandIntro(title: 'خطة الأكل الأسبوعية 📅', icon: Icons.calendar_month_outlined,
        subtitle: 'خطط ${weekDays.length * mealNames.length} وجبة للأسبوع. المختار: $occupied وجبات.'),
      const SizedBox(height: 16),
      OutlinedButton.icon(onPressed: occupied == 0 ? null : () {
        controller.addPlannedMealsToShopping();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تمت إضافة مقادير الوجبات للمشتريات')));
      }, icon: const Icon(Icons.shopping_basket_outlined), label: const Text('أضف مقادير خطة الأسبوع للمشتريات')),
      const SizedBox(height: 8),
      ...List.generate(7, (day) => Card(margin: const EdgeInsets.only(bottom: 12), child: Padding(
        padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [const Icon(Icons.calendar_today_outlined, size: 17, color: KitchenBrand.tomato),
            const SizedBox(width: 9), Text(weekDays[day], style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17))]),
          const SizedBox(height: 7),
          ...List.generate(3, (meal) {
            final id = controller.plannedMeals['$day:$meal'];
            final recipe = id == null ? null : controller.find(id);
            return ListTile(dense: true, contentPadding: EdgeInsets.zero,
              leading: Text(['🌅', '☀️', '🌙'][meal], style: const TextStyle(fontSize: 24)),
              title: Text('${mealNames[meal]}: ${recipe?.name ?? 'اختر وجبة'}'),
              trailing: const Icon(Icons.edit_outlined, size: 18),
              onTap: () => _choose(context, day, meal));
          }),
        ])))),
    ]);
  });
}