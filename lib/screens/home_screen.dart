import 'package:flutter/material.dart';
import '../core/kitchen_controller.dart';
import '../core/models.dart';
import '../core/dessert_toppings.dart';
import '../widgets/recipe_card.dart';
import '../branding/brand_widgets.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.controller});
  final KitchenController controller;
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String selectedCountry = 'all';
  String selectedCategory = 'الكل';
  bool onlyFavorites = false;
  final TextEditingController searchController = TextEditingController();
  String query = '';
  @override
  void dispose() { searchController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final control = widget.controller;
    return AnimatedBuilder(animation: control, builder: (context, _) {
      // Offer relevant subcategories for the chosen kitchen rather than mixing
      // Egyptian mahashi/tawagen into other cuisines' navigation.
      const egyptianCategoryOrder = <String>[
        'أطباق رئيسية', 'إفطار', 'أكلات شعبية', 'محاشي',
        'طواجن وصواني', 'أسماك ومأكولات بحرية', 'شوربات',
        'مقبلات وسلطات', 'مخبوزات ومعجنات', 'حلويات',
        'كتالوج الحلويات',
      ];
      final categorySet = control.recipes
          .where((r) => selectedCountry == 'all' || r.country == selectedCountry)
          .map((r) => r.category).toSet();
      final otherCategories = categorySet.where((category) =>
          selectedCountry != 'eg' ||
          !egyptianCategoryOrder.contains(category)).toList()..sort();
      final categories = <String>[
        'الكل',
        if (selectedCountry == 'eg')
          ...egyptianCategoryOrder.where(categorySet.contains),
        ...otherCategories,
      ];
      final egyptianCount = control.recipes.where((r) => r.country == 'eg').length;
      final filtered = control.recipes.where((r) {
        final q = query.trim();
        return (selectedCountry == 'all' || r.country == selectedCountry) &&
          (selectedCategory == 'الكل' || r.category == selectedCategory) &&
          (!onlyFavorites || control.favorites.contains(r.id)) &&
          (q.isEmpty || r.name.contains(q) || r.description.contains(q) ||
          r.ingredients.any((i) => i.name.contains(q)) || r.tags.any((t) => t.contains(q)) ||
          r.toppingIds.any((id) => DessertToppings.byId[id]?.name.contains(q) ?? false));
      }).toList();
      return CustomScrollView(slivers: [
        SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.fromLTRB(16, 10, 16, 8), child:
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF7B2C20), KitchenBrand.tomato, KitchenBrand.amber], begin: Alignment.topRight, end: Alignment.bottomLeft),
                borderRadius: BorderRadius.circular(24)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('وصفات من العالم • على ذوقك', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12)),
                const SizedBox(height: 5),
                const Text('كل مطابخ العالم في مطبخك ✨',
                  style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 21)),
                const SizedBox(height: 8),
                Text('اكتشف ${control.recipes.length} وصفة من ${countries.length} مطابخ، واطبخ خطوة بخطوة.',
                  style: const TextStyle(color: Colors.white, fontSize: 14)),
                const SizedBox(height: 12),
                const Row(children: [Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
                  SizedBox(width: 7), Text('مقادير قابلة للتعديل • وصفات بدون إنترنت', style: TextStyle(color: Colors.white, fontSize: 12))]),
              ]),
            ),
            const SizedBox(height: 12),
            Card(child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              leading: const CircleAvatar(child: Text('🇪🇬', style: TextStyle(fontSize: 22))),
              title: const Text('المطبخ المصري',
                style: TextStyle(fontWeight: FontWeight.w900)),
              subtitle: Text('$egyptianCount وصفة • أكلات شعبية ومحاشي وطواجن وأسماك وحلويات'),
              trailing: const Icon(Icons.arrow_back_ios_new, size: 16),
              onTap: () => setState(() {
                selectedCountry = 'eg'; selectedCategory = 'الكل';
                onlyFavorites = false;
                query = ''; searchController.clear();
              }),
            )),
            const SizedBox(height: 6),
            Card(child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              leading: const CircleAvatar(child: Icon(Icons.icecream_outlined)),
              title: const Text('كتالوج الحلويات المصرية',
                style: TextStyle(fontWeight: FontWeight.w900)),
              subtitle: const Text('14 صنف أساسي وإضافات اختياريّة — وصفات منزلية مستوحاة'),
              trailing: const Icon(Icons.arrow_back_ios_new, size: 16),
              onTap: () => setState(() {
                selectedCountry = 'eg';
                selectedCategory = 'كتالوج الحلويات';
                onlyFavorites = false;
                query = '';
                searchController.clear();
              }),
            )),
            const SizedBox(height: 12),
            TextField(controller: searchController, onChanged: (v) => setState(() => query = v),
              decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'ابحث عن أكلة أو مكوّن...')),
            const SizedBox(height: 19),
            const BrandSectionTitle('المطابخ'),
            const SizedBox(height: 8),
            SizedBox(height: 52, child: ListView(scrollDirection: Axis.horizontal, children: [
              Padding(padding: const EdgeInsetsDirectional.only(end: 7),
                child: ChoiceChip(label: const Text('🌍 الكل'), selected: selectedCountry == 'all',
                  onSelected: (_) => setState(() { selectedCountry = 'all'; selectedCategory = 'الكل'; }))),
              ...countries.entries.map((c) => Padding(
                padding: const EdgeInsetsDirectional.only(end: 7),
                child: ChoiceChip(label: Text('${c.value.$2} ${c.value.$1}'),
                  selected: selectedCountry == c.key,
                  onSelected: (_) => setState(() { selectedCountry = c.key; selectedCategory = 'الكل'; })))),
            ])),
            const SizedBox(height: 10),
            SizedBox(height: 49, child: ListView(scrollDirection: Axis.horizontal, children: [
              ...categories.map((c) => Padding(padding: const EdgeInsetsDirectional.only(end: 7),
                child: FilterChip(label: Text(c), selected: selectedCategory == c,
                  onSelected: (_) => setState(() => selectedCategory = c)))),
            ])),
            Row(children: [
              Expanded(child: BrandSectionTitle('الوصفات (${filtered.length})')), 
              TextButton.icon(onPressed: () => setState(() => onlyFavorites = !onlyFavorites),
                icon: Icon(onlyFavorites ? Icons.favorite : Icons.favorite_border, size: 18),
                label: const Text('المفضلة')),
            ]),
          ]))),
        SliverPadding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 24), sliver: filtered.isEmpty
          ? const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.all(32),
              child: Center(child: Text('لا توجد وصفات مطابقة. جرّب بحثًا أو تصنيفًا آخر.'))))
          : SliverList(delegate: SliverChildBuilderDelegate(
              (ctx, i) => RecipeCard(recipe: filtered[i], controller: control), childCount: filtered.length))),
      ]);
    });
  }
}