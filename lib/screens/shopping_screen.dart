import 'package:flutter/material.dart';
import '../core/kitchen_controller.dart';
import '../core/models.dart';
import '../branding/brand_widgets.dart';

class ShoppingScreen extends StatefulWidget {
  const ShoppingScreen({super.key, required this.controller});
  final KitchenController controller;
  @override
  State<ShoppingScreen> createState() => _ShoppingScreenState();
}

class _ShoppingScreenState extends State<ShoppingScreen> {
  Future<void> _addItem() async {
    final name = TextEditingController();
    final quantity = TextEditingController(text: '1');
    final unit = TextEditingController(text: 'حبة');
    final item = await showDialog<(String, double, String)>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('أضف مشتريات'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: name, decoration: const InputDecoration(labelText: 'اسم المكوّن')),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: TextField(controller: quantity, keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'الكمية'))),
          const SizedBox(width: 8),
          Expanded(child: TextField(controller: unit, decoration: const InputDecoration(labelText: 'الوحدة'))),
        ]),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
        FilledButton(onPressed: () {
          final parsed = double.tryParse(quantity.text.replaceAll(',', '.'));
          if (name.text.trim().isEmpty || parsed == null || parsed <= 0) return;
          Navigator.pop(ctx, (name.text.trim(), parsed, unit.text.trim()));
        }, child: const Text('أضف')),
      ],
    ));
    if (item != null) widget.controller.addManualItem(item.$1, item.$2, item.$3);
    name.dispose(); quantity.dispose(); unit.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(animation: widget.controller,
    builder: (context, _) {
      final c = widget.controller;
      final checked = c.shopping.where((e) => e.checked).length;
      return ListView(padding: const EdgeInsets.all(16), children: [
        BrandIntro(title: 'قائمة المشتريات 🛒', icon: Icons.shopping_basket_outlined,
          subtitle: 'لديك ${c.shopping.length} مكوّن • تم شراء $checked'),
        const SizedBox(height: 12),
        if (c.shopping.isNotEmpty) LinearProgressIndicator(
          value: checked / c.shopping.length, minHeight: 7, borderRadius: BorderRadius.circular(8)),
        const SizedBox(height: 14),
        FilledButton.icon(onPressed: _addItem, icon: const Icon(Icons.add), label: const Text('أضف مكوّنًا يدويًا')),
        const SizedBox(height: 9),
        if (checked > 0) OutlinedButton.icon(
          onPressed: c.removeCheckedItems,
          icon: const Icon(Icons.cleaning_services_outlined),
          label: const Text('حذف المشتريات المكتملة')),
        const SizedBox(height: 12),
        if (c.shopping.isEmpty) const Card(child: Padding(padding: EdgeInsets.all(28), child:
          Column(children: [Icon(Icons.shopping_basket_outlined, size: 48), SizedBox(height: 8),
            Text('قائمة المشتريات فاضية'), Text('افتح وصفة وأضف مكوناتها الناقصة، أو أضف عنصرًا يدويًا.')]))),
        ...c.shopping.map((e) => Card(child: Row(children: [
          Expanded(child: CheckboxListTile(
            title: Text(e.name, style: TextStyle(decoration: e.checked ? TextDecoration.lineThrough : null)),
            subtitle: Text('${Ingredient.amount(e.quantity)} ${e.unit}'),
            value: e.checked, onChanged: (v) => c.setItemChecked(e, v ?? false))),
          IconButton(tooltip: 'حذف', onPressed: () => c.removeItem(e),
            icon: const Icon(Icons.delete_outline)),
        ]))),
        const SizedBox(height: 30),
      ]);
    });
}