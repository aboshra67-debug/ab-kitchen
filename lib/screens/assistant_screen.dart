import 'package:flutter/material.dart';
import '../core/kitchen_controller.dart';
import '../core/assistant_service.dart';
import '../branding/brand_widgets.dart';

class AssistantScreen extends StatefulWidget {
  const AssistantScreen({super.key, required this.controller});
  final KitchenController controller;
  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends State<AssistantScreen> {
  final input = TextEditingController();
  final List<(bool, String)> messages = [
    (false, 'أهلًا! 👨‍🍳 قول لي محتاج تطبخ إيه، أو اسأل عن البدائل والوصفات السريعة.'),
  ];
  final CookingAssistantProvider provider = OfflineCookingAssistant();
  bool busy = false;

  @override
  void dispose() { input.dispose(); super.dispose(); }
  Future<void> send([String? sample]) async {
    final prompt = (sample ?? input.text).trim();
    if (prompt.isEmpty || busy) return;
    input.clear();
    setState(() { messages.add((true, prompt)); busy = true; });
    try {
      final response = await provider.answer(prompt, widget.controller);
      if (mounted) setState(() => messages.add((false, response)));
    } catch (_) {
      if (mounted) setState(() => messages.add((false, 'تعذّر تجهيز الرد حاليًا.')));
    } finally { if (mounted) setState(() => busy = false); }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(children: [
      Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 8), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const BrandIntro(title: 'مساعد الطبخ ✨', icon: Icons.auto_awesome_outlined,
          subtitle: 'اسأل عن الأكلات السريعة والبدائل والمقادير. مساعد محلي لا يحتاج إنترنت.'),
        const SizedBox(height: 6),
        const Text('نسخة أولية بقواعد محلية، وليست محادثة ذكاء اصطناعي سحابية.', style: TextStyle(fontSize: 11)),
        const SizedBox(height: 10),
        SizedBox(height: 44, child: ListView(scrollDirection: Axis.horizontal, children: [
          ...['عندي مكونات في البيت', 'عايز أكلة سريعة', 'إيه بديل اللبن؟', 'نصائح سلامة الطعام']
            .map((s) => Padding(padding: const EdgeInsetsDirectional.only(end: 6),
              child: ActionChip(label: Text(s), onPressed: () => send(s)))),
        ])),
      ])),
      Expanded(child: ListView.builder(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: messages.length, itemBuilder: (context, i) {
          final m = messages[i];
          return Align(alignment: m.$1 ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 310),
              margin: const EdgeInsets.only(bottom: 11), padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: m.$1 ? colors.primaryContainer : colors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(18)),
              child: Text(m.$2, style: const TextStyle(height: 1.5))));
        })),
      if (busy) const LinearProgressIndicator(minHeight: 2),
      SafeArea(top: false, child: Padding(padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
        child: Row(children: [
          Expanded(child: TextField(controller: input, minLines: 1, maxLines: 3,
            textInputAction: TextInputAction.send, onSubmitted: (_) => send(),
            decoration: const InputDecoration(hintText: 'اسأل مساعد المطبخ...'))),
          const SizedBox(width: 8),
          IconButton.filled(onPressed: busy ? null : () => send(), icon: const Icon(Icons.send)),
        ]))),
    ]);
  }
}