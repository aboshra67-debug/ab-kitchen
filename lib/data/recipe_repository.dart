import 'dart:convert';
import 'package:flutter/services.dart';
import '../core/models.dart';

class RecipeRepository {
  static Future<List<Recipe>> load() async {
    final raw = await rootBundle.loadString('assets/data/recipes_ar.json');
    final parsed = jsonDecode(raw) as List<dynamic>;
    return List.unmodifiable(parsed.map((e) => Recipe.fromJson(e as Map<String, dynamic>)));
  }
}