import 'models.dart';

/// Shared optional extras for the home dessert catalogue. A single base recipe
/// plus a small topping registry avoids duplicating nearly identical recipes.
class DessertTopping {
  const DessertTopping(this.id, this.name, this.ingredient, this.instruction);
  final String id;
  final String name;
  final Ingredient ingredient;
  final String instruction;
  CookingStep get step => CookingStep(
    title: 'إضافة $name', body: instruction, minutes: 2);
}

abstract final class DessertToppings {
  static const byId = <String, DessertTopping>{
    'cream': DessertTopping('cream', 'قشطة', Ingredient(name:'قشطة بلدي', quantity:120, unit:'جرام'), 'ضع القشطة على وجه الحلوى عند التقديم، أو وزّعها بين الطبقات.'),
    'mango': DessertTopping('mango', 'مانجو', Ingredient(name:'مانجو مكعبات', quantity:220, unit:'جرام'), 'أضف مكعبات المانجو الطازجة بعد أن تبرد الحلوى.'),
    'lotus': DessertTopping('lotus', 'لوتس', Ingredient(name:'بسكويت لوتس مطحون', quantity:90, unit:'جرام'), 'وزّع بسكويت اللوتس المطحون على الوجه عند التقديم.'),
    'oreo': DessertTopping('oreo', 'أوريو', Ingredient(name:'بسكويت أوريو', quantity:100, unit:'جرام'), 'فتّت البسكويت وأضفه فوق الكريمة أو بين الطبقات.'),
    'chocolate': DessertTopping('chocolate', 'شوكولاتة', Ingredient(name:'صوص شوكولاتة', quantity:120, unit:'جرام'), 'وزّع صوص الشوكولاتة على الحلوى بعد أن تبرد قليلًا.'),
    'nuts': DessertTopping('nuts', 'مكسرات', Ingredient(name:'مكسرات محمصة', quantity:80, unit:'جرام'), 'حمّص المكسرات إن لزم واتركها تبرد ثم رشها على وجه الحلوى.'),
    'pistachio': DessertTopping('pistachio', 'فستق', Ingredient(name:'فستق مجروش', quantity:65, unit:'جرام'), 'رش الفستق المجروش على الوجه قبل التقديم.'),
    'caramel': DessertTopping('caramel', 'كراميل', Ingredient(name:'صوص كراميل', quantity:110, unit:'جرام'), 'أضف صوص الكراميل بعد أن تصبح الحلوى جاهزة للتقديم.'),
    'strawberry': DessertTopping('strawberry', 'فراولة', Ingredient(name:'فراولة طازجة', quantity:200, unit:'جرام'), 'قطّع الفراولة بعد غسلها جيدًا وضعها على الحلوى الباردة.'),
  };

  static List<String> validChoices(Recipe recipe, Iterable<String> selected) {
    final choices = selected.toSet();
    return recipe.toppingIds.where((id) => choices.contains(id) && byId.containsKey(id)).toList();
  }

  static List<Ingredient> ingredientsFor(Recipe recipe, Iterable<String> selected) {
    final ingredients = <Ingredient>[...recipe.ingredients];
    for (final id in validChoices(recipe, selected)) {
      ingredients.add(byId[id]!.ingredient);
    }
    // Combine exact same ingredient and unit; never silently mix incompatible units.
    final merged = <String, Ingredient>{};
    for (final ingredient in ingredients) {
      final key = '${ingredient.name.trim()}|${ingredient.unit.trim()}';
      final previous = merged[key];
      merged[key] = previous == null ? ingredient : Ingredient(
        name: previous.name, unit: previous.unit,
        quantity: previous.quantity + ingredient.quantity);
    }
    return merged.values.toList(growable: false);
  }

  static List<CookingStep> stepsFor(Recipe recipe, Iterable<String> selected) => [
    ...recipe.steps,
    for (final id in validChoices(recipe, selected)) byId[id]!.step,
  ];
}