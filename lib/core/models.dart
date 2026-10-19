import 'dart:math' as math;

class Ingredient {
  const Ingredient({required this.name, required this.quantity, required this.unit});
  final String name;
  final double quantity;
  final String unit;

  factory Ingredient.fromJson(Map<String, dynamic> json) => Ingredient(
        name: json['name'] as String,
        quantity: (json['quantity'] as num).toDouble(),
        unit: json['unit'] as String,
      );

  double forServings(int servings, int baseServings) =>
      quantity * servings / math.max(1, baseServings);

  static String amount(double number) {
    if (number >= 10) return number.toStringAsFixed(number % 1 == 0 ? 0 : 1);
    return number.toStringAsFixed(number % 1 == 0 ? 0 : 2)
        .replaceAll(RegExp(r'0+$'), '')
        .replaceAll(RegExp(r'\.$'), '');
  }
}

class CookingStep {
  const CookingStep({required this.title, required this.body, required this.minutes});
  final String title;
  final String body;
  final int minutes;

  factory CookingStep.fromJson(Map<String, dynamic> json) => CookingStep(
        title: json['title'] as String,
        body: json['body'] as String,
        minutes: (json['minutes'] as num?)?.toInt() ?? 0,
      );
}

class Recipe {
  const Recipe({
    required this.id,
    required this.name,
    required this.country,
    required this.category,
    required this.emoji,
    required this.description,
    required this.minutes,
    required this.difficulty,
    required this.servings,
    required this.ingredients,
    required this.steps,
    required this.tags,
  });
  final String id;
  final String name;
  final String country;
  final String category;
  final String emoji;
  final String description;
  final int minutes;
  final String difficulty;
  final int servings;
  final List<Ingredient> ingredients;
  final List<CookingStep> steps;
  final List<String> tags;

  factory Recipe.fromJson(Map<String, dynamic> json) => Recipe(
        id: json['id'] as String,
        name: json['name'] as String,
        country: json['country'] as String,
        category: json['category'] as String,
        emoji: json['emoji'] as String,
        description: json['description'] as String,
        minutes: (json['minutes'] as num).toInt(),
        difficulty: json['difficulty'] as String,
        servings: (json['servings'] as num).toInt(),
        ingredients: (json['ingredients'] as List)
            .map((e) => Ingredient.fromJson(e as Map<String, dynamic>))
            .toList(growable: false),
        steps: (json['steps'] as List)
            .map((e) => CookingStep.fromJson(e as Map<String, dynamic>))
            .toList(growable: false),
        tags: (json['tags'] as List<dynamic>? ?? []).cast<String>(),
      );
}

class ShopItem {
  ShopItem({required this.name, required this.quantity, required this.unit, this.checked = false});
  final String name;
  double quantity;
  final String unit;
  bool checked;
  String get key => '${name.trim().toLowerCase()}|${unit.trim().toLowerCase()}';
  Map<String, dynamic> toJson() => {'name': name, 'quantity': quantity, 'unit': unit, 'checked': checked};
  factory ShopItem.fromJson(Map<String, dynamic> json) => ShopItem(
        name: json['name'] as String,
        quantity: (json['quantity'] as num).toDouble(),
        unit: json['unit'] as String,
        checked: json['checked'] as bool? ?? false,
      );
}

const countries = <String, (String, String)>{
  'eg': ('مصر', '🇪🇬'),
  'sa': ('السعودية', '🇸🇦'),
  'sy': ('سوريا', '🇸🇾'),
  'tr': ('تركيا', '🇹🇷'),
  'it': ('إيطاليا', '🇮🇹'),
  'in': ('الهند', '🇮🇳'),
  'ma': ('المغرب', '🇲🇦'),
  'lb': ('لبنان', '🇱🇧'),
};
const weekDays = ['السبت', 'الأحد', 'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة'];
const mealNames = ['إفطار', 'غداء', 'عشاء'];