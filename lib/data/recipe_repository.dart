import 'dart:convert';
import 'package:flutter/services.dart';
import '../core/models.dart';

class RecipeRepository {
  static Future<List<Recipe>> load() async {
    // Append-only catalog: keep all original Egyptian and world recipes intact.
    final raw = await rootBundle.loadString('assets/data/recipes_ar.json');
    final saudiRaw = await rootBundle.loadString('assets/data/saudi_phase1_recipes.json');
    final base = jsonDecode(raw) as List<dynamic>;
    final saudi = jsonDecode(saudiRaw) as List<dynamic>;
    final phase2Raw = await rootBundle.loadString('assets/data/saudi_phase2_recipes.json');
    final phase2 = jsonDecode(phase2Raw) as List<dynamic>;
    final phase3Raw = await rootBundle.loadString('assets/data/saudi_phase3_recipes.json');
    final phase3 = jsonDecode(phase3Raw) as List<dynamic>;
    final syrianRaw = await rootBundle.loadString('assets/data/syrian_phase1_recipes.json');
    final syrian = jsonDecode(syrianRaw) as List<dynamic>;
    final syrianPhase2Raw = await rootBundle.loadString('assets/data/syrian_phase2_recipes.json');
    final syrianPhase2 = jsonDecode(syrianPhase2Raw) as List<dynamic>;
    final syrianPhase3Raw = await rootBundle.loadString('assets/data/syrian_phase3_recipes.json');
    final syrianPhase3 = jsonDecode(syrianPhase3Raw) as List<dynamic>;
    final all = <Recipe>[
      ...base.map((e) => Recipe.fromJson(e as Map<String, dynamic>)),
      ...saudi.map((e) => Recipe.fromJson(e as Map<String, dynamic>)),
      ...phase2.map((e) => Recipe.fromJson(e as Map<String, dynamic>)),
      ...phase3.map((e) => Recipe.fromJson(e as Map<String, dynamic>)),
      ...syrian.map((e) => Recipe.fromJson(e as Map<String, dynamic>)),
      ...syrianPhase2.map((e) => Recipe.fromJson(e as Map<String, dynamic>)),
      ...syrianPhase3.map((e) => Recipe.fromJson(e as Map<String, dynamic>)),
    ];
    assert(all.length == all.map((r) => r.id).toSet().length,
      'Duplicate recipe ID across catalogs');
    return List.unmodifiable(all);
  }
}
