import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';

class KitchenController extends ChangeNotifier {
  KitchenController(this.recipes, this._prefs);
  final List<Recipe> recipes;
  final SharedPreferences _prefs;
  static const _stateKey = 'ab_kitchen_v1';
  final Set<String> favorites = {};
  final Set<String> pantry = {};
  final List<ShopItem> shopping = [];
  final Map<String, String> plannedMeals = {};
  final Map<String, int> cookingProgress = {};
  bool darkMode = false;
  int defaultServings = 4;

  static KitchenController open(List<Recipe> recipes, SharedPreferences prefs) {
    final c = KitchenController(recipes, prefs);
    final data = prefs.getString(_stateKey);
    if (data != null) {
      try {
        final state = jsonDecode(data) as Map<String, dynamic>;
        c.favorites.addAll((state['favorites'] as List<dynamic>? ?? []).cast<String>());
        c.pantry.addAll((state['pantry'] as List<dynamic>? ?? []).cast<String>());
        c.shopping.addAll((state['shopping'] as List<dynamic>? ?? [])
            .map((e) => ShopItem.fromJson(e as Map<String, dynamic>)));
        c.plannedMeals.addAll((state['plannedMeals'] as Map<String, dynamic>? ?? {})
            .map((key, value) => MapEntry(key, value as String)));
        c.cookingProgress.addAll((state['cookingProgress'] as Map<String, dynamic>? ?? {})
            .map((key, value) => MapEntry(key, (value as num).toInt())));
        c.darkMode = state['darkMode'] as bool? ?? false;
        c.defaultServings = ((state['defaultServings'] as num?)?.toInt() ?? 4).clamp(1, 12).toInt();
      } catch (_) {
        // Preserve user data stored on disk; do not overwrite unreadable state.
        c._canSave = false;
      }
    }
    return c;
  }

  bool _canSave = true;
  bool get hasStorageError => !_canSave;
  Recipe? find(String id) {
    for (final r in recipes) { if (r.id == id) return r; }
    return null;
  }

  void _save() {
    notifyListeners();
    if (!_canSave) return;
    final state = {
      'favorites': favorites.toList(),
      'pantry': pantry.toList(),
      'shopping': shopping.map((e) => e.toJson()).toList(),
      'plannedMeals': plannedMeals,
      'cookingProgress': cookingProgress,
      'darkMode': darkMode,
      'defaultServings': defaultServings,
    };
    _prefs.setString(_stateKey, jsonEncode(state));
  }

  int getCookingStep(Recipe recipe) =>
      (cookingProgress[recipe.id] ?? 0).clamp(0, recipe.steps.length - 1).toInt();
  void setCookingStep(Recipe recipe, int index) {
    if (recipe.steps.isEmpty) return;
    cookingProgress[recipe.id] = index.clamp(0, recipe.steps.length - 1).toInt();
    _save();
  }
  void finishCooking(String recipeId) { cookingProgress.remove(recipeId); _save(); }

  void toggleFavorite(String id) { favorites.contains(id) ? favorites.remove(id) : favorites.add(id); _save(); }
  void togglePantry(String name) { pantry.contains(name) ? pantry.remove(name) : pantry.add(name); _save(); }
  void setDarkMode(bool value) { darkMode = value; _save(); }
  void setDefaultServings(int value) { defaultServings = value.clamp(1, 12).toInt(); _save(); }
  void setPlannedMeal(int day, int meal, String? id) {
    if (day < 0 || day > 6 || meal < 0 || meal > 2) return;
    final key = '$day:$meal';
    if (id == null) { plannedMeals.remove(key); }
    else if (find(id) != null) { plannedMeals[key] = id; }
    _save();
  }
  void addIngredient(Ingredient ingredient, int servings, int baseServings) {
    final quantity = ingredient.forServings(servings, baseServings);
    final incoming = ShopItem(name: ingredient.name, quantity: quantity, unit: ingredient.unit);
    final index = shopping.indexWhere((x) => x.key == incoming.key);
    if (index >= 0) { shopping[index].quantity += quantity; shopping[index].checked = false; }
    else { shopping.add(incoming); }
    _save();
  }
  /// Adds the missing recipe ingredients in a single state transition.
  /// A marked ingredient is already prepared and must not be purchased again.
  void addMissingRecipeToShopping(Recipe recipe, int servings, Set<int> readyIndices) {
    if (servings < 1 || servings > 12) return;
    for (var index = 0; index < recipe.ingredients.length; index++) {
      final ingredient = recipe.ingredients[index];
      if (readyIndices.contains(index) || pantry.contains(ingredient.name)) continue;
      final quantity = ingredient.forServings(servings, recipe.servings);
      final incoming = ShopItem(name: ingredient.name, quantity: quantity, unit: ingredient.unit);
      final existingIndex = shopping.indexWhere((item) => item.key == incoming.key);
      if (existingIndex >= 0) {
        shopping[existingIndex].quantity += quantity;
        shopping[existingIndex].checked = false;
      } else {
        shopping.add(incoming);
      }
    }
    _save();
  }

  void addRecipeToShopping(Recipe recipe, int servings, {bool onlyMissing = false}) {
    // Batch change avoids saving after every ingredient.
    for (final i in recipe.ingredients) {
      if (onlyMissing && pantry.contains(i.name)) continue;
      final newItem = ShopItem(name: i.name, quantity: i.forServings(servings, recipe.servings), unit: i.unit);
      final index = shopping.indexWhere((x) => x.key == newItem.key);
      if (index >= 0) { shopping[index].quantity += newItem.quantity; shopping[index].checked = false; }
      else { shopping.add(newItem); }
    }
    _save();
  }
  void addPlannedMealsToShopping() {
    for (final id in plannedMeals.values) {
      final r = find(id);
      if (r == null) continue;
      for (final i in r.ingredients) {
        final next = ShopItem(name: i.name, quantity: i.forServings(defaultServings, r.servings), unit: i.unit);
        final idx = shopping.indexWhere((x) => x.key == next.key);
        if (idx >= 0) { shopping[idx].quantity += next.quantity; shopping[idx].checked = false; }
        else { shopping.add(next); }
      }
    }
    _save();
  }
  void addManualItem(String name, double quantity, String unit) {
    if (name.trim().isEmpty || !quantity.isFinite || quantity <= 0) return;
    final item = ShopItem(name: name.trim(), quantity: quantity, unit: unit.trim().isEmpty ? 'قطعة' : unit.trim());
    final idx = shopping.indexWhere((x) => x.key == item.key);
    if (idx >= 0) { shopping[idx].quantity += quantity; shopping[idx].checked = false; }
    else { shopping.add(item); }
    _save();
  }
  void setItemChecked(ShopItem item, bool checked) { item.checked = checked; _save(); }
  void removeItem(ShopItem item) { shopping.remove(item); _save(); }
  void removeCheckedItems() { shopping.removeWhere((e) => e.checked); _save(); }
  double matchRatio(Recipe r) => r.ingredients.isEmpty ? 0 :
      r.ingredients.where((i) => pantry.contains(i.name)).length / r.ingredients.length;
  List<Recipe> suggestedFromPantry() {
    final all = [...recipes];
    all.sort((a,b) {
      final diff = matchRatio(b).compareTo(matchRatio(a));
      return diff != 0 ? diff : a.minutes.compareTo(b.minutes);
    });
    return all;
  }
  void clearUserData() {
    favorites.clear(); pantry.clear(); shopping.clear(); plannedMeals.clear(); cookingProgress.clear();
    darkMode = false; defaultServings = 4;
    _canSave = true; _save();
  }
}