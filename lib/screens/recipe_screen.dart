import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../core/models.dart';
import '../core/kitchen_controller.dart';
import '../branding/brand_widgets.dart';

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
  @override
  void initState() { super.initState(); servings = widget.controller.defaultServings; }
  @override
  Widget build(BuildContext context) {
    final r = widget.recipe;
    final c = widget.controller;
    final color = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(r.name), actions: [
        AnimatedBuilder(animation: c, builder: (_, __) => IconButton(
          tooltip: 'المفضلة',
          icon: Icon(c.favorites.contains(r.id) ? Icons.favorite : Icons.favorite_border),
          onPressed: () => c.toggleFavorite(r.id))),
      ]),
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 0, 16, 110), children: [
        Container(height: 180, alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFFFFE4C7), Color(0xFFFFF0E3)]),
            borderRadius: BorderRadius.circular(24)),
          child: Stack(alignment: Alignment.center, children: [
            Text(r.emoji, style: const TextStyle(fontSize: 102)),
            const Positioned(top: 12, right: 12, child: BrandLogo(size: 37)),
          ])),
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
        const SizedBox(height: 18),
        Row(children: [
          const Expanded(child: BrandSectionTitle('المقادير')),
          IconButton.filledTonal(onPressed: servings > 1 ? () => setState(() => servings--) : null,
            icon: const Icon(Icons.remove)),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 10), child: Text('$servings أفراد', style: const TextStyle(fontWeight: FontWeight.w800))),
          IconButton.filledTonal(onPressed: servings < 12 ? () => setState(() => servings++) : null,
            icon: const Icon(Icons.add)),
        ]),
        const SizedBox(height: 7),
        ...r.ingredients.asMap().entries.map((entry) {
          final i = entry.value;
          return CheckboxListTile(
            contentPadding: EdgeInsets.zero, dense: true,
            value: ready.contains(entry.key),
            title: Text(i.name, style: TextStyle(decoration: ready.contains(entry.key) ? TextDecoration.lineThrough : null)),
            secondary: Text('${Ingredient.amount(i.forServings(servings, r.servings))} ${i.unit}',
              style: const TextStyle(fontWeight: FontWeight.w800)),
            onChanged: (v) => setState(() { v == true ? ready.add(entry.key) : ready.remove(entry.key); }),
          );
        }),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          icon: const Icon(Icons.add_shopping_cart),
          label: const Text('أضف المكونات غير الموجودة لقائمة المشتريات'),
          onPressed: () {
            c.addMissingRecipeToShopping(r, servings, ready);
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تحديث قائمة المشتريات')));
          }),
        const SizedBox(height: 22),
        const BrandSectionTitle('خطوات التحضير'),
        const SizedBox(height: 12),
        ...r.steps.asMap().entries.map((e) => Card(child: Padding(
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
      bottomNavigationBar: SafeArea(minimum: const EdgeInsets.all(15), child: FilledButton.icon(
        icon: const Icon(Icons.play_arrow), label: const Text('ابدأ الطبخ خطوة بخطوة'),
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CookingScreen(recipe: r))),
      )),
    );
  }
}

class CookingScreen extends StatefulWidget {
  const CookingScreen({super.key, required this.recipe});
  final Recipe recipe;
  @override
  State<CookingScreen> createState() => _CookingScreenState();
}

class _CookingScreenState extends State<CookingScreen> with WidgetsBindingObserver {
  int index = 0;
  int secondsLeft = 0;
  DateTime? deadline;
  Timer? countdown;
  final FlutterTts tts = FlutterTts();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refreshCountdown();
  }

  Future<void> speakStep() async {
    final current = widget.recipe.steps[index];
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
    final seconds = widget.recipe.steps[index].minutes * 60;
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
      index = next.clamp(0, widget.recipe.steps.length - 1).toInt();
      secondsLeft = 0;
      deadline = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final recipe = widget.recipe;
    final current = recipe.steps[index];
    return Scaffold(
      appBar: AppBar(title: Text('نطبخ ${recipe.name}')),
      body: SafeArea(child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        children: [
          LinearProgressIndicator(
            value: (index + 1) / recipe.steps.length,
            minHeight: 9,
            borderRadius: BorderRadius.circular(8),
          ),
          const SizedBox(height: 14),
          Text('الخطوة ${index + 1} من ${recipe.steps.length}',
            style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 24),
          Center(child: Container(
            padding: const EdgeInsets.all(19),
            decoration: BoxDecoration(gradient: const LinearGradient(
              colors: [Color(0xFFFFE4C7), Color(0xFFFFF8F1)]),
              borderRadius: BorderRadius.circular(30)),
            child: Text(recipe.emoji, style: const TextStyle(fontSize: 78)))),
          const SizedBox(height: 22),
          Text(current.title, textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          Text(current.body, textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 17, height: 1.7)),
          const SizedBox(height: 20),
          Center(child: OutlinedButton.icon(
            onPressed: speakStep,
            icon: const Icon(Icons.volume_up_outlined),
            label: const Text('اسمع شرح الخطوة 🔊'),
          )),
          if (current.minutes > 0) ...[
            const SizedBox(height: 20),
            Text(secondsLeft > 0
              ? '${(secondsLeft ~/ 60).toString().padLeft(2, '0')}:${(secondsLeft % 60).toString().padLeft(2, '0')}'
              : 'الوقت المقترح: ${current.minutes} دقيقة',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            OutlinedButton.icon(onPressed: startTimer,
              icon: const Icon(Icons.timer_outlined),
              label: const Text('تشغيل / إعادة المؤقت')),
          ],
        ],
      )),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: Row(children: [
          Expanded(child: OutlinedButton(
            onPressed: index > 0 ? () => move(index - 1) : null,
            child: const Text('السابق'))),
          const SizedBox(width: 12),
          Expanded(child: FilledButton(
            onPressed: () {
              if (index != recipe.steps.length - 1) {
                move(index + 1);
                return;
              }
              countdown?.cancel();
              deadline = null;
              unawaited(tts.stop());
              showDialog<void>(context: context, builder: (ctx) => AlertDialog(
                title: const Text('بالهنا والشفا! 🎉'),
                content: const Text('خلصت خطوات الوصفة. تقدر تعيدها أو ترجع للوصفة.'),
                actions: [TextButton(
                  onPressed: () { Navigator.pop(ctx); Navigator.pop(context); },
                  child: const Text('إنهاء'))],
              ));
            },
            child: Text(index == recipe.steps.length - 1 ? 'خلصت ✅' : 'التالي'))),
        ]),
      ),
    );
  }
}