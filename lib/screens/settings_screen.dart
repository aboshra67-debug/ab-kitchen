import 'package:flutter/material.dart';
import '../core/kitchen_controller.dart';
import '../branding/brand_widgets.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.controller});
  final KitchenController controller;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('الإعدادات')),
    body: AnimatedBuilder(animation: controller, builder: (context, _) => ListView(
      padding: const EdgeInsets.all(16), children: [
        const BrandIntro(title: 'إعدادات AB Kitchen', icon: Icons.tune_outlined,
          subtitle: 'مطبخ العالم • المظهر الموحّد الدافئ • إصدار تجريبي 0.3.0'),
        const SizedBox(height: 12),
        const Card(child: ListTile(leading: BrandLogo(size: 48),
          title: Text('هوية AB Kitchen الدافئة'),
          subtitle: Text('البرتقالي والأحمر • سيتم إضافة ثيمات اختيارية لاحقًا.'))),
        const SizedBox(height: 20),
        Card(child: SwitchListTile(
          title: const Text('الوضع الداكن'), subtitle: const Text('يمكن تغييره في أي وقت'),
          secondary: const Icon(Icons.dark_mode_outlined),
          value: controller.darkMode, onChanged: controller.setDarkMode)),
        Card(child: ListTile(
          leading: const Icon(Icons.people_outline),
          title: const Text('عدد الأشخاص الافتراضي'),
          subtitle: const Text('تُضبط عليه المقادير عند فتح أي وصفة'),
          trailing: DropdownButton<int>(value: controller.defaultServings,
            items: List.generate(12, (i) => DropdownMenuItem(value: i+1, child: Text('${i+1}'))),
            onChanged: (v) { if (v != null) controller.setDefaultServings(v); }))),
        const SizedBox(height: 20),
        const BrandSectionTitle('البيانات والخصوصية'),
        const SizedBox(height: 6),
        const ListTile(leading: Icon(Icons.offline_bolt_outlined),
          title: Text('الوصفات متاحة بلا إنترنت'),
          subtitle: Text('الوصفات والمفضلة والمشتريات والخطة تحفظ محليًا على الجهاز.')),
        const ListTile(leading: Icon(Icons.smart_toy_outlined),
          title: Text('المساعد الحالي محلي'),
          subtitle: Text('لا تُرسل أسئلتك إلى نموذج سحابي في هذا الإصدار.')),
        if (controller.hasStorageError) const Card(child: Padding(
          padding: EdgeInsets.all(12), child: Text('تحذير: بيانات التطبيق المحفوظة غير قابلة للقراءة. لم نكتب فوقها تلقائيًا.'))),
        OutlinedButton.icon(icon: const Icon(Icons.delete_outline), label: const Text('مسح البيانات المحلية'),
          onPressed: () async {
            final confirmed = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
              title: const Text('مسح البيانات؟'),
              content: const Text('سيُحذف سجل المفضلة والمشتريات ومكونات البيت وخطة الوجبات من هذا الجهاز. لا يمكن التراجع.'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
                TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('مسح')),
              ],
            ));
            if (confirmed == true) controller.clearUserData();
          }),
        const SizedBox(height: 12),
        Text('نسخة تطوير أولية • الصور الفوتوغرافية والوصفات الموسّعة والمساعد السحابي والنسخ الاحتياطي والمزامنة ليست ضمن هذه النسخة.',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12)),
      ])),
  );
}