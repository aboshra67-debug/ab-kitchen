import 'kitchen_controller.dart';

/// Extensible AI provider contract. Offline provider below is rule-based,
/// never mislabeled as a remote generative AI model.
abstract class CookingAssistantProvider {
  Future<String> answer(String question, KitchenController kitchen);
}

class OfflineCookingAssistant implements CookingAssistantProvider {
  @override
  Future<String> answer(String question, KitchenController c) async {
    final q = question.trim().toLowerCase();
    if (q.isEmpty) return 'اكتب سؤالك علشان أقدر أساعدك.';
    if (q.contains('بديل') || q.contains('استبدل') || q.contains('بدل')) {
      if (q.contains('لبن') || q.contains('حليب')) return 'في بعض الوصفات ينفع استبدال الحليب بحليب نباتي غير محلى، لكن النتيجة والقوام قد يتغيّران. في الحلويات اتأكد من ملاءمة البديل للوصفة.';
      if (q.contains('بيض')) return 'في بعض المخبوزات يمكن تجربة ¼ كوب مهروس موز أو تفاح لكل بيضة، لكنه مش بديل مناسب لكل وصفة، خصوصًا اللي بيعتمد قوامها على البيض.';
      if (q.contains('سمن') || q.contains('زبدة')) return 'في أكلات كثيرة ممكن تستبدل السمن بزيت نباتي مناسب، لكن الطعم والقوام هيختلفوا. راجع الوصفة قبل الاستبدال.';
      return 'قول لي اسم المكوّن والوصفة اللي عايز تبدله فيها؛ الاختيار بيختلف من أكلة للتانية.';
    }
    if (q.contains('موجود') || q.contains('عندي') || q.contains('الثلاجة') || q.contains('مكونات')) {
      final options = c.suggestedFromPantry().where((r) => c.matchRatio(r) > .30).take(3).toList();
      if (options.isEmpty) return 'ادخل على تبويب «مطبخي» وحدد مكوّناتك أولًا؛ بعدها أقدر أقترح عليك وصفات قريبة من الموجود عندك.';
      return 'أقرب وصفات للمكونات المسجلة عندك:\n${options.map((r) => '• ${r.name} — ${(c.matchRatio(r)*100).round()}٪ من المكونات متوفرة').join('\n')}';
    }
    if (q.contains('سريع') || q.contains('وقت') || q.contains('نص ساعة')) {
      final quick = c.recipes.where((r) => r.minutes <= 30).take(5);
      return 'وصفات سريعة عندنا:\n${quick.map((r) => '• ${r.name} (${r.minutes} دقيقة)').join('\n')}';
    }
    if (q.contains('دجاج') || q.contains('فراخ') || q.contains('رز') || q.contains('أرز')) {
      final chicken = q.contains('دجاج') || q.contains('فراخ');
      final terms = chicken ? ['دجاج','فراخ'] : ['أرز','رز'];
      final suggestions = c.recipes.where((r) => r.ingredients.any((i) => terms.any((t) => i.name.contains(t)))).take(5);
      return suggestions.isEmpty ? 'ملقيتش وصفة مطابقة في المكتبة المحلية الحالية.' :
        'ممكن تجرب:\n${suggestions.map((r) => '• ${r.name} (${r.minutes} دقيقة)').join('\n')}';
    }
    if (q.contains('حرارة') || q.contains('الفرن')) {
      return 'سخّن الفرن مسبقًا للحرارة المذكورة في الوصفة، واستخدم ميزان حرارة مناسب إن أمكن. زمن الخبز بيختلف حسب الفرن وحجم الصينية.';
    }
    if (q.contains('سلامة') || q.contains('ني')) {
      return 'اغسل إيديك وأدواتك جيدًا، وافصل النيّ عن الجاهز للأكل. استخدم ميزان حرارة للتأكد من نضج اللحوم والدواجن بدل الاعتماد على اللون فقط.';
    }
    final matched = c.recipes.where((r) => r.name.contains(q) || q.contains(r.name)).take(3).toList();
    if (matched.isNotEmpty) return 'لقيت الوصفة دي في المكتبة: ${matched.map((r) => r.name).join('، ')}. تقدر تفتحها من شاشة اكتشف لمراجعة المقادير والخطوات.';
    return 'أقدر أساعدك حاليًا في اقتراح وصفات سريعة، مكونات البيت، وبدائل بعض المكونات. المساعد الحالي يعمل بقواعد محلية دون اتصال بنموذج ذكاء اصطناعي خارجي.';
  }
}