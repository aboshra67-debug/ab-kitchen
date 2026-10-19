import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../core/models.dart';
import '../core/kitchen_controller.dart';
import '../core/dessert_toppings.dart';
import '../branding/brand_widgets.dart';
import '../widgets/recipe_photo.dart';

class RecipeScreen extends StatefulWidget {
  const RecipeScreen({super.key, required this.recipe, required this.controller});
  final Recipe recipe;
  final KitchenController controller;
  @override
  State<RecipeScreen> createState() => _RecipeScreenState();
}

class _RecipeScreenState extends State<RecipeScreen> {
  late int servings;
  final Set<int> ready = {};
  final Set<String> selectedToppings = {};
  @override
  void initState() {
    super.initState();
    servings = widget.controller.defaultServings;
    selectedToppings.addAll(widget.controller.toppingsFor(widget.recipe));
  }
  @override
  Widget build(BuildContext context) {
    final r = widget.recipe;
    final c = widget.controller;
    final color = Theme.of(context).colorScheme;
    final ingredients = DessertToppings.ingredientsFor(r, selectedToppings);
    return Scaffold(
      appBar: AppBar(title: Text(r.name), actions: [
        AnimatedBuilder(animation: c, builder: (_, __) => IconButton(
          tooltip: 'المفضلة',
          icon: Icon(c.favorites.contains(r.id) ? Icons.favorite : Icons.favorite_border),
          onPressed: () => c.toggleFavorite(r.id))),
      ]),
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 0, 16, 110), children: [
        RecipePhoto(recipe: r, hero: true, height: 222, borderRadius: 24),
        const SizedBox(height: 16),
        Text(r.name, style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w900)),
        const SizedBox(height: 5),
        Text(r.description, style: TextStyle(color: color.onSurfaceVariant)),
        const SizedBox(height: 10),
        Wrap(spacing: 8, children: [
          Chip(avatar: const Icon(Icons.schedule, size: 18), label: Text('${r.minutes} دقيقة')),
          Chip(avatar: const Icon(Icons.equalizer, size: 18), label: Text(r.difficulty)),
          Chip(label: Text('${countries[r.country]?.$2 ?? ''} ${countries[r.country]?.$1 ?? ''}')),
        ]),
        if (r.isDessertCatalogue) ...[
          const SizedBox(height: 12),
          Card(color: color.secondaryContainer.withValues(alpha: .4), child: const Padding(
            padding: EdgeInsets.all(13), child: Text(
              'وصفة منزلية مستوحاة من نوع الحلوى، وليست وصفة أصلية أو كتالوجًا رسميًا للمحل.',
              style: TextStyle(fontSize: 12)))),
          const SizedBox(height: 12),
          const BrandSectionTitle('اختار النكهة والإضافات'),
          const SizedBox(height: 6),
          Text('الوصفة الأساسية واحدة. اختر أكثر من إضافة، والمقادير والخطوات تتغيّر تلقائيًا.',
            style: TextStyle(fontSize: 12, color: color.onSurfaceVariant)),
          const SizedBox(height: 9),
          Wrap(spacing: 7, runSpacing: 4, children: [
            for (final id in r.toppingIds)
              if (DessertToppings.byId.containsKey(id))
                FilterChip(
                  key: ValueKey('extra_$id'),
                  label: Text(DessertToppings.byId[id]!.name),
                  selected: selectedToppings.contains(id),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) { selectedToppings.add(id); }
                      else { selectedToppings.remove(id); }
                      ready.clear();
                    });
                    c.setDessertToppings(r, selectedToppings);
                  }),
          ]),
        ],
        const SizedBox(height: 18),
        const BrandSectionTitle('المقادير'),
        Card(color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: .35),
          child: Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(children: [
              const Expanded(child: Text('عدد الأفراد', style: TextStyle(fontWeight: FontWeight.w800))),
              IconButton.filledTonal(tooltip: 'تقليل الأفراد',
                onPressed: servings > 1 ? () => setState(() => servings--) : null,
                icon: const Icon(Icons.remove)),
              Padding(padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text('$servings أفراد', style: const TextStyle(fontWeight: FontWeight.w800))),
              IconButton.filledTonal(tooltip: 'زيادة الأفراد',
                onPressed: servings < 12 ? () => setState(() => servings++) : null,
                icon: const Icon(Icons.add)),
            ]))),
        const SizedBox(height: 7),
        ...ingredients.asMap().entries.map((entry) {
          final i = entry.value;
          return Card(margin: const EdgeInsets.only(bottom: 6), child: CheckboxListTile(
            contentPadding: const EdgeInsetsDirectional.only(start: 9, end: 13),
            dense: true,
            value: ready.contains(entry.key),
            title: Text(i.name, style: TextStyle(fontWeight: FontWeight.w600,
              decoration: ready.contains(entry.key) ? TextDecoration.lineThrough : null)),
            secondary: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(color: color.primaryContainer.withValues(alpha: .55),
                borderRadius: BorderRadius.circular(15)),
              child: Text('${Ingredient.amount(i.forServings(servings, r.servings))} ${i.unit}',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12))),
            onChanged: (v) => setState(() { v == true ? ready.add(entry.key) : ready.remove(entry.key); }),
          ));
        }),
        const SizedBox(height: 16),
        const BrandSectionTitle('خطوات التحضير'),
        const SizedBox(height: 12),
        ...DessertToppings.stepsFor(r, selectedToppings).asMap().entries.map((e) => Card(child: Padding(
          padding: const EdgeInsets.all(14), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            CircleAvatar(radius: 17, child: Text('${e.key+1}')),
            const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(e.value.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              const SizedBox(height: 5), Text(e.value.body),
              if (e.value.minutes > 0) Padding(padding: const EdgeInsets.only(top: 6),
                child: Text('⏱ ${e.value.minutes} دقيقة', style: TextStyle(color: color.primary, fontSize: 12))),
            ])),
          ]))),
        ),
      ]),
      bottomNavigationBar: SafeArea(minimum: const EdgeInsets.fromLTRB(12, 5, 12, 12),
        child: Row(children: [
          Expanded(flex: 3, child: FilledButton.icon(
            icon: const Icon(Icons.play_arrow_rounded),
            label: Text(c.cookingProgress.containsKey(r.id) ? 'كمّل الطبخ' : 'ابدأ الطبخ'),
            onPressed: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => CookingScreen(recipe: r, controller: c, steps: DessertToppings.stepsFor(r, selectedToppings)))).then((_) {
                if (mounted) setState(() {});
              }),
          )),
          const SizedBox(width: 8),
          Expanded(flex: 2, child: OutlinedButton.icon(
            icon: const Icon(Icons.shopping_basket_outlined, size: 19),
            label: const Text('المشتريات', style: TextStyle(fontSize: 13)),
            onPressed: () {
              c.addMissingRecipeToShopping(r, servings, ready, ingredients: ingredients);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('أُضيفت المكونات الناقصة للمشتريات')));
            },
          )),
        ]),
      ),
    );
  }
}

class CookingScreen extends StatefulWidget {
  const CookingScreen({super.key, required this.recipe, required this.controller, this.steps});
  final Recipe recipe;
  final KitchenController controller;
  final List<CookingStep>? steps;
  @override
  State<CookingScreen> createState() => _CookingScreenState();
}

class _CookingScreenState extends State<CookingScreen> with WidgetsBindingObserver {
  int index = 0;
  int secondsLeft = 0;
  DateTime? deadline;
  Timer? countdown;
  final FlutterTts tts = FlutterTts();
  List<CookingStep> get activeSteps => widget.steps ?? widget.recipe.steps;

  @override
  void initState() {
    super.initState();
    index = widget.controller.getCookingStep(widget.recipe, totalSteps: activeSteps.length);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refreshCountdown();
  }

  Future<void> speakStep() async {
    final current = activeSteps[index];
    try {
      await tts.stop();
      if (!mounted) return;
      await tts.setLanguage('ar-EG');
      await tts.setSpeechRate(.45);
      await tts.speak('${current.title}. ${current.body}');
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('الصوت العربي غير متاح حاليًا على الجهاز. تحقق من إعدادات تحويل النص إلى كلام.')));
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    countdown?.cancel();
    unawaited(tts.stop());
    super.dispose();
  }

  void _refreshCountdown() {
    if (!mounted || deadline == null) return;
    final remaining = deadline!.difference(DateTime.now()).inSeconds;
    final next = remaining < 0 ? 0 : remaining + 1;
    if (secondsLeft != next) setState(() => secondsLeft = next);
    if (next == 0) {
      deadline = null;
      countdown?.cancel();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('انتهى وقت الخطوة ✅')));
    }
  }

  void startTimer() {
    countdown?.cancel();
    final seconds = activeSteps[index].minutes * 60;
    setState(() {
      secondsLeft = seconds;
      deadline = seconds > 0 ? DateTime.now().add(Duration(seconds: seconds)) : null;
    });
    if (seconds > 0) {
      countdown = Timer.periodic(const Duration(seconds: 1), (_) => _refreshCountdown());
    }
  }

  void move(int next) {
    countdown?.cancel();
    unawaited(tts.stop());
    setState(() {
      index = next.clamp(0, activeSteps.length - 1).toInt();
      secondsLeft = 0;
      deadline = null;
    });
    widget.controller.setCookingStep(widget.recipe, index, totalSteps: activeSteps.length);
  }

  @override
  Widget build(BuildContext context) {
    final recipe = widget.recipe;
    final current = activeSteps[index];
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('ابدأ الطبخ'), actions: [
        IconButton(tooltip: 'حفظ والعودة', icon: const Icon(Icons.bookmark_border),
          onPressed: () => Navigator.pop(context)),
      ]),
      body: SafeArea(child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 2, 16, 24),
        children: [
          Card(child: Padding(padding: const EdgeInsets.all(9), child: Row(children: [
            Expanded(flex: 2, child: RecipePhoto(recipe: recipe, height: 116, borderRadius: 16)),
            const SizedBox(width: 12),
            Expanded(flex: 3, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(recipe.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
              const SizedBox(height: 8),
              Text('${recipe.minutes} دقيقة • ${recipe.difficulty}',
                style: TextStyle(color: colors.onSurfaceVariant, fontSize: 13)),
            ])),
          ]))),
          const SizedBox(height: 12),
          Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text('الخطوة ${index+1} من ${activeSteps.length}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
              const SizedBox(height: 12),
              LinearProgressIndicator(value: (index+1)/activeSteps.length, minHeight: 8,
                borderRadius: BorderRadius.circular(8)),
              const SizedBox(height: 12),
              SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [
                for (var i=0;i<activeSteps.length;i++) Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3), child: CircleAvatar(
                    radius: 15,
                    backgroundColor: i==index ? colors.primary : colors.primaryContainer,
                    child: Text('${i+1}', style: TextStyle(fontSize: 12,
                      color: i==index ? colors.onPrimary : colors.onPrimaryContainer)),
                  ),
                ),
              ])),
            ]))),
          const SizedBox(height: 12),
          Card(child: Padding(padding: const EdgeInsets.all(17), child: Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              OutlinedButton.icon(onPressed: speakStep,
                icon: const Icon(Icons.volume_up_outlined, size: 19),
                label: const Text('اسمع الخطوة')),
              if (current.minutes > 0) Text(secondsLeft > 0
                ? '${(secondsLeft ~/ 60).toString().padLeft(2,'0')}:${(secondsLeft%60).toString().padLeft(2,'0')}'
                : '${current.minutes} دقيقة',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 19, color: colors.primary)),
            ]),
            const SizedBox(height: 14),
            Text(current.title, textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 21)),
            const SizedBox(height: 10),
            Text(current.body, textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, height: 1.75)),
            if (current.minutes > 0) ...[
              const SizedBox(height: 15),
              OutlinedButton.icon(onPressed: startTimer,
                icon: const Icon(Icons.timer_outlined),
                label: Text(secondsLeft > 0 ? 'إعادة المؤقت' : 'تشغيل مؤقت الخطوة')),
            ],
          ]))),
          const SizedBox(height: 12),
          Text('التقدّم محفوظ تلقائيًا على الجهاز ويمكنك إكمال الوصفة لاحقًا.',
            textAlign: TextAlign.center, style: TextStyle(
              color: colors.onSurfaceVariant, fontSize: 12)),
        ],
      )),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(14, 7, 14, 14),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(children: [
            Expanded(child: OutlinedButton.icon(
              onPressed: index > 0 ? () => move(index-1) : null,
              icon: const Icon(Icons.arrow_forward_ios, size: 15),
              label: const Text('السابق'))),
            const SizedBox(width: 10),
            Expanded(child: FilledButton.icon(
              icon: const Icon(Icons.arrow_back_ios, size: 15),
              onPressed: () {
                if (index < activeSteps.length-1) { move(index+1); return; }
                countdown?.cancel(); deadline=null; unawaited(tts.stop());
                widget.controller.finishCooking(recipe.id);
                showDialog<void>(context: context, builder: (ctx) => AlertDialog(
                  title: const Text('بالهنا والشفا! 🎉'),
                  content: const Text('اكتملت خطوات الوصفة بنجاح.'),
                  actions: [TextButton(onPressed: () {
                    Navigator.pop(ctx); Navigator.pop(context);
                  }, child: const Text('إنهاء'))],
                ));
              },
              label: Text(index == activeSteps.length-1 ? 'خلصت' : 'التالي'))),
          ]),
          const SizedBox(height: 6),
          TextButton.icon(onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.bookmark_outline),
            label: const Text('حفظ ومتابعة لاحقًا')),
        ]),
      ),
    );
  }
}