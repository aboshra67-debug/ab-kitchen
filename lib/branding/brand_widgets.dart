import 'package:flutter/material.dart';

/// Approved AB Kitchen warm identity. Pink and other optional themes come later.
abstract final class KitchenBrand {
  static const tomato = Color(0xFFD84B29);
  static const amber = Color(0xFFFF9C28);
  static const cocoa = Color(0xFF43241C);
  static const cream = Color(0xFFFFF8F1);
  static const roseCream = Color(0xFFFFF0E5);
  static const herb = Color(0xFF347744);
  static const logo = 'assets/branding/ab_kitchen_logo.jpg';
}

class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.size = 48});
  final double size;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(size * .23),
    child: Image.asset(KitchenBrand.logo, height: size, width: size,
      fit: BoxFit.cover, filterQuality: FilterQuality.medium,
      semanticLabel: 'شعار AB Kitchen'),
  );
}

/// Compact, reusable section hero. The title remains discoverable by screen readers
/// and existing widget smoke tests. Does not alter application state.
class BrandIntro extends StatelessWidget {
  const BrandIntro({super.key, required this.title, required this.subtitle, required this.icon});
  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final ink = dark ? Colors.white : KitchenBrand.cocoa;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: dark ? [const Color(0xFF533327), const Color(0xFF352620)]
            : [const Color(0xFFFFF0DA), const Color(0xFFFFFAF6)],
          begin: Alignment.topRight, end: Alignment.bottomLeft),
        border: Border.all(color: KitchenBrand.amber.withValues(alpha: dark ? .28 : .22)),
        borderRadius: BorderRadius.circular(24)),
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        Container(width: 50, height: 50,
          decoration: BoxDecoration(color: KitchenBrand.tomato.withValues(alpha: .12),
            borderRadius: BorderRadius.circular(17)),
          child: Icon(icon, color: dark ? KitchenBrand.amber : KitchenBrand.tomato, size: 27)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: TextStyle(color: ink, fontSize: 21, fontWeight: FontWeight.w900)),
          const SizedBox(height: 5),
          Text(subtitle, style: TextStyle(color: ink.withValues(alpha: .75),
            fontSize: 12.5, height: 1.55)),
        ])),
        const Icon(Icons.auto_awesome_rounded, color: KitchenBrand.amber, size: 21),
      ]),
    );
  }
}

class BrandSectionTitle extends StatelessWidget {
  const BrandSectionTitle(this.text, {super.key, this.trailing});
  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 9, top: 8),
    child: Row(children: [
      Container(width: 4, height: 22, decoration: BoxDecoration(
        color: KitchenBrand.tomato, borderRadius: BorderRadius.circular(4))),
      const SizedBox(width: 8),
      Expanded(child: Text(text, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900))),
      if (trailing != null) trailing!,
    ]));
}