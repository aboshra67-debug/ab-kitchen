import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/kitchen_controller.dart';
import 'core/models.dart';
import 'data/recipe_repository.dart';
import 'screens/home_screen.dart';
import 'screens/pantry_screen.dart';
import 'screens/planner_screen.dart';
import 'screens/shopping_screen.dart';
import 'screens/assistant_screen.dart';
import 'screens/settings_screen.dart';
import 'branding/brand_widgets.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    final results = await Future.wait([RecipeRepository.load(), SharedPreferences.getInstance()]);
    final controller = KitchenController.open(
      results[0] as List<Recipe>, results[1] as SharedPreferences);
    // Release smoke-test marker: initialized preferences + loaded every recipe.
    debugPrint('AB_KITCHEN_STARTUP_READY recipes=${controller.recipes.length}');
    runApp(ABKitchenApp(controller: controller));
  } catch (error) {
    runApp(MaterialApp(
      home: Scaffold(body: Center(child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text('تعذّر تحميل بيانات التطبيق. تحقق من ملفات الوصفات ثم أعد التشغيل.\n$error',
          textAlign: TextAlign.center, textDirection: TextDirection.rtl),
      ))),
    ));
  }
}

class ABKitchenApp extends StatelessWidget {
  const ABKitchenApp({super.key, required this.controller});
  final KitchenController controller;

  ThemeData _theme(Brightness mode) {
    final scheme = ColorScheme.fromSeed(seedColor: KitchenBrand.tomato, brightness: mode)
      .copyWith(primary: mode == Brightness.light ? KitchenBrand.tomato : const Color(0xFFFFA778),
        secondary: KitchenBrand.amber,
        surface: mode == Brightness.light ? Colors.white : const Color(0xFF25211E),
        onSurface: mode == Brightness.light ? KitchenBrand.cocoa : Colors.white);
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      brightness: mode,
      scaffoldBackgroundColor: mode == Brightness.light ? KitchenBrand.cream : const Color(0xFF171513),
      cardTheme: CardThemeData(
        elevation: 0, color: mode == Brightness.light ? Colors.white : const Color(0xFF25211E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      appBarTheme: const AppBarTheme(backgroundColor: Colors.transparent, centerTitle: false,
        surfaceTintColor: Colors.transparent, titleSpacing: 16),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: mode == Brightness.light ? KitchenBrand.roseCream : const Color(0xFF28211F),
        indicatorColor: mode == Brightness.light ? const Color(0xFFFFD4BA) : const Color(0xFF633A30),
        labelTextStyle: WidgetStatePropertyAll(TextStyle(fontSize: 11,
          fontWeight: FontWeight.w700, color: scheme.onSurface))),
      filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(
        minimumSize: const Size(0, 46), shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15)))),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        filled: true, fillColor: mode == Brightness.light ? Colors.white : const Color(0xFF282420),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (context, _) => MaterialApp(
      title: 'AB Kitchen – مطبخ العالم',
      debugShowCheckedModeBanner: false,
      theme: _theme(Brightness.light),
      darkTheme: _theme(Brightness.dark),
      themeMode: controller.darkMode ? ThemeMode.dark : ThemeMode.light,
      builder: (context, child) => Directionality(textDirection: TextDirection.rtl, child: child ?? const SizedBox()),
      home: KitchenShell(controller: controller),
    ),
  );
}

class KitchenShell extends StatefulWidget {
  const KitchenShell({super.key, required this.controller});
  final KitchenController controller;
  @override
  State<KitchenShell> createState() => _KitchenShellState();
}

class _KitchenShellState extends State<KitchenShell> {
  int tab = 0;
  static const names = ['اكتشف', 'مطبخي', 'جدول الأسبوع', 'المشتريات', 'المساعد'];
  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      HomeScreen(controller: widget.controller),
      PantryScreen(controller: widget.controller),
      PlannerScreen(controller: widget.controller),
      ShoppingScreen(controller: widget.controller),
      AssistantScreen(controller: widget.controller),
    ];
    return Scaffold(
      appBar: AppBar(
        title: Row(mainAxisSize: MainAxisSize.min, children: [
          const BrandLogo(size: 42), const SizedBox(width: 9),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('AB Kitchen', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 19, letterSpacing: -.4)),
            Text(names[tab], style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ]),
        ]),
        actions: [
          IconButton(tooltip: 'الإعدادات', icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => SettingsScreen(controller: widget.controller)))),
        ],
      ),
      body: SafeArea(child: IndexedStack(index: tab, children: pages)),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab, labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        height: 74,
        onDestinationSelected: (i) => setState(() => tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.explore_outlined), selectedIcon: Icon(Icons.explore), label: 'اكتشف'),
          NavigationDestination(icon: Icon(Icons.kitchen_outlined), selectedIcon: Icon(Icons.kitchen), label: 'مطبخي'),
          NavigationDestination(icon: Icon(Icons.calendar_month_outlined), selectedIcon: Icon(Icons.calendar_month), label: 'الجدول'),
          NavigationDestination(icon: Icon(Icons.shopping_basket_outlined), selectedIcon: Icon(Icons.shopping_basket), label: 'المشتريات'),
          NavigationDestination(icon: Icon(Icons.auto_awesome_outlined), selectedIcon: Icon(Icons.auto_awesome), label: 'المساعد'),
        ],
      ),
    );
  }
}