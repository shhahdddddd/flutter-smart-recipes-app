import 'dart:convert';

import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;

import '../../../../core/utils/constants.dart';
import '../../../../injection_container.dart' as di;
import '../../../auth/domain/repositories/auth_repository.dart';
import '../models/recipe.dart';

class RecipesController extends GetxController {
  final AuthRepository _authRepository = di.sl<AuthRepository>();
  final GetStorage _storage = di.sl<GetStorage>();

  static const String _cachedRecipesKey = 'cached_recipes';
  
  final RxList<Recipe> recipes = <Recipe>[].obs;
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;

  Future<void> loadRecipes() async {
    try {
      isLoading.value = true;
      error.value = '';
      
      final session = _authRepository.getCachedSession();
      if (session == null) throw Exception('Session expired');

      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/recipes'),
        headers: {'Authorization': 'Bearer ${session.token}'},
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        final List<dynamic> data = decoded['data'] as List<dynamic>? ?? [];

        final parsed = data.map((item) {
          final map = item as Map<String, dynamic>;

          final List<dynamic> ingredientList = map['ingredients'] as List<dynamic>? ?? [];
          final ingredients = ingredientList.map((ing) {
            final i = ing as Map<String, dynamic>;
            final name = (i['name'] ?? '').toString();
            final quantity = (i['quantity'] ?? '').toString();
            final note = (i['note'] ?? '').toString();

            final parts = <String>[];
            if (quantity.isNotEmpty) parts.add(quantity);
            if (name.isNotEmpty) parts.add(name);
            if (note.isNotEmpty) parts.add('($note)');
            return parts.join(' ');
          }).where((s) => s.trim().isNotEmpty).toList();

          final List<dynamic> instructions = map['instructions'] as List<dynamic>? ?? [];
          final steps = instructions
              .map((step) => (step as Map<String, dynamic>)['description']?.toString() ?? '')
              .where((s) => s.trim().isNotEmpty)
              .toList();

          final cookingTime = map['cookingTime'];
          final duration = cookingTime == null
              ? 'N/A'
              : '$cookingTime min';

          final List<dynamic> tagsRaw = map['tags'] as List<dynamic>? ?? [];
          final tags = tagsRaw.map((t) => t.toString()).toList();

          final nutrition = map['nutrition'] is Map<String, dynamic>
              ? (map['nutrition'] as Map<String, dynamic>)
              : null;
          double? calories = _toDouble(nutrition?['calories'] ?? map['calories']);
          double? protein = _toDouble(nutrition?['protein'] ?? map['protein']);
          double? sugar = _toDouble(nutrition?['sugar'] ?? map['sugar']);
          double? carbs = _toDouble(nutrition?['carbs'] ?? map['carbohydrates'] ?? map['carbs']);

          final rawImage = (map['image'] ?? '').toString();
          final imageUrl = _pickImage(
            rawImage,
            tags,
            (map['category'] ?? '').toString(),
            (map['title'] ?? '').toString(),
            (map['_id'] ?? '').toString(),
          );

          return Recipe(
            id: (map['_id'] ?? '').toString(),
            title: (map['title'] ?? '').toString(),
            description: (map['description'] ?? '').toString(),
            duration: duration,
            servings: 2,
            imageUrl: imageUrl,
            tags: tags,
            ingredients: ingredients,
            steps: steps,
            tips: const [],
            calories: calories,
            protein: protein,
            sugar: sugar,
            carbs: carbs,
          );
        }).toList();

        final seen = <String>{};
        final unique = <Recipe>[];
        for (final r in parsed) {
          final key = r.title.trim().toLowerCase();
          if (key.isEmpty) continue;
          if (seen.add(key)) unique.add(r);
        }

        recipes.value = unique;
        _storage.write(
          _cachedRecipesKey,
          unique.map(_recipeToJson).toList(),
        );
      } else {
        throw Exception('Failed to load recipes');
      }
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onInit() {
    final cached = _storage.read<List>(_cachedRecipesKey);
    if (cached is List) {
      final restored = cached
          .whereType<Map>()
          .map((m) => Map<String, dynamic>.from(m))
          .map(_recipeFromJson)
          .toList();
      if (restored.isNotEmpty) {
        recipes.value = restored;
      }
    }

    loadRecipes();
    super.onInit();
  }

  Future<void> generateSimilar(Recipe recipe) async {
    try {
      final session = _authRepository.getCachedSession();
      if (session == null) {
        Get.snackbar('Session expired', 'Please log in again', snackPosition: SnackPosition.BOTTOM);
        return;
      }
      final ingredients = recipe.ingredients.map((e) => e.toString()).toList();
      final resp = await http.post(
        Uri.parse('${AppConstants.baseUrl}/ai/generate-recipes'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${session.token}',
        },
        body: jsonEncode({
          'ingredients': ingredients,
          'preferences': {},
        }),
      );
      if (resp.statusCode == 200) {
        Get.snackbar('Generated', 'Similar recipes created for you', snackPosition: SnackPosition.BOTTOM);
        await loadRecipes();
      } else {
        Get.snackbar('Error', 'Could not generate similar recipes', snackPosition: SnackPosition.BOTTOM);
      }
    } catch (_) {
      Get.snackbar('Error', 'Unexpected error generating similar recipes', snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> ensureMinimumForCategory(String category, {int min = 10}) async {
    try {
      final c = category.toLowerCase();
      List<Recipe> current = recipes.where((r) {
        final tags = r.tags.map((t) => t.toLowerCase()).toList();
        final title = r.title.toLowerCase();
        final desc = r.description.toLowerCase();
        bool m = c == 'all' || tags.any((t) => t.contains(c)) || title.contains(c) || desc.contains(c);
        if (c.contains('vegetarian')) m = m || tags.any((t) => t.contains('vegetarian') || t.contains('vegan'));
        if (c.contains('fast')) {
          final match = RegExp(r'(\d+)').firstMatch(r.duration);
          final minutes = int.tryParse(match?.group(1) ?? '0') ?? 0;
          m = m || (minutes > 0 && minutes <= 20);
        }
        if (c.contains('healthy')) m = m || tags.any((t) => t.contains('healthy') || t.contains('heart') || t.contains('omega') || t.contains('high protein'));
        if (c.contains('cheap') || c.contains('budget')) m = m || tags.any((t) => t.contains('cheap') || t.contains('budget'));
        if (c.contains('zero waste')) m = m || tags.any((t) => t.contains('zero waste'));
        return m;
      }).toList();
      if (current.length >= min) return;

      final session = _authRepository.getCachedSession();
      if (session == null) return;
      final user = session.user;

      List<String> baseIngredients = ['rice', 'vegetables', 'olive oil'];
      if (c.contains('fast')) {
        baseIngredients = ['eggs', 'pasta', 'tomato'];
      } else if (c.contains('vegetarian')) {
        baseIngredients = ['tofu', 'beans', 'vegetables'];
      } else if (c.contains('cheap') || c.contains('budget')) {
        baseIngredients = ['rice', 'beans', 'onion'];
      } else if (c.contains('healthy')) {
        baseIngredients = ['quinoa', 'chicken', 'broccoli'];
      } else if (c.contains('zero waste')) {
        baseIngredients = ['bread', 'vegetables', 'cheese'];
      }

      final prefs = {
        'diet': user.lifestylePreferences.isNotEmpty ? user.lifestylePreferences.first : null,
        'allergies': [...user.allergies, ...user.intolerances],
        'excludedIngredients': user.optionalTags,
        'healthGoals': [...user.weightManagementGoals, ...user.dietaryGoals],
        'conditions': [...user.conditions, ...user.chronicConditions],
        'lifestylePreferences': user.lifestylePreferences,
        'category': category,
      };

      final resp = await http.post(
        Uri.parse('${AppConstants.baseUrl}/ai/generate-recipes'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${session.token}',
        },
        body: jsonEncode({
          'ingredients': baseIngredients,
          'preferences': prefs,
        }),
      );

      if (resp.statusCode == 200) {
        await loadRecipes();
      }
    } catch (_) {}
  }

  Future<void> addToFavorites(Recipe recipe) async {
    try {
      final session = _authRepository.getCachedSession();
      if (session == null) {
        Get.snackbar('Session expired', 'Please log in again', snackPosition: SnackPosition.BOTTOM);
        return;
      }

      String recipeId = recipe.id;
      final isMongoId = RegExp(r'^[a-f0-9]{24}$').hasMatch(recipeId);
      if (!isMongoId) {
        final match = RegExp(r'(\d+)').firstMatch(recipe.duration);
        final cookingTime = int.tryParse(match?.group(1) ?? '') ?? 20;
        final payload = {
          'title': recipe.title,
          'description': recipe.description,
          'ingredients': recipe.ingredients.map((s) => {'name': s, 'quantity': ''}).toList(),
          'instructions': recipe.steps.asMap().entries.map((e) => {'step': e.key + 1, 'description': e.value}).toList(),
          'cookingTime': cookingTime,
          'difficulty': 'easy',
          'category': 'dinner',
          'tags': recipe.tags,
          'isAIGenerated': false,
        };
        final createResp = await http.post(
          Uri.parse('${AppConstants.baseUrl}/recipes'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${session.token}',
          },
          body: jsonEncode(payload),
        );
        if (createResp.statusCode == 201) {
          final decoded = jsonDecode(createResp.body) as Map<String, dynamic>;
          recipeId = (decoded['data'] as Map<String, dynamic>)['_id']?.toString() ?? recipeId;
        } else {
          Get.snackbar('Save failed', 'Could not create recipe', snackPosition: SnackPosition.BOTTOM);
          return;
        }
      }

      final favResp = await http.post(
        Uri.parse('${AppConstants.baseUrl}/users/favorites/$recipeId'),
        headers: {'Authorization': 'Bearer ${session.token}'},
      );
      if (favResp.statusCode == 200) {
        Get.snackbar('Saved', 'Recipe added to favorites', snackPosition: SnackPosition.BOTTOM);
      } else {
        Get.snackbar('Save failed', 'Could not add to favorites', snackPosition: SnackPosition.BOTTOM);
      }
    } catch (_) {
      Get.snackbar('Save failed', 'Unexpected error while saving recipe', snackPosition: SnackPosition.BOTTOM);
    }
  }

  String _pickImage(String raw, List<String> tags, String category, String title, String id) {
  if (raw.trim().isNotEmpty) return raw;
  final pool = [
    'https://images.unsplash.com/photo-1528712306091-ed0763094c98?auto=format&fit=crop&w=800&q=80',
    'https://images.unsplash.com/photo-1478144592103-25e218a04891?auto=format&fit=crop&w=800&q=80',
    'https://images.unsplash.com/photo-1612872087720-bb876e01fd95?auto=format&fit=crop&w=800&q=80',
    'https://images.unsplash.com/photo-1506086679525-9f1d5f0de1c0?auto=format&fit=crop&w=800&q=80',
    'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?auto=format&fit=crop&w=800&q=80',
    'https://images.unsplash.com/photo-1455619452474-d2be8b1e70cd?auto=format&fit=crop&w=800&q=80',
    'https://images.unsplash.com/photo-1512058564366-18510be2f8ff?auto=format&fit=crop&w=800&q=80',
    'https://images.unsplash.com/photo-1481931713751-5f8f9c63b6a0?auto=format&fit=crop&w=800&q=80',
    'https://images.unsplash.com/photo-1490645935967-10de6ba17061?auto=format&fit=crop&w=800&q=80',
    'https://images.unsplash.com/photo-1467003909585-2f8a72700288?auto=format&fit=crop&w=800&q=80',
    'https://images.unsplash.com/photo-1432139555190-58524dae6a55?auto=format&fit=crop&w=800&q=80',
    'https://images.unsplash.com/photo-1445979323117-80453f573b71?auto=format&fit=crop&w=800&q=80',
  ];
  final basis = '${category.toLowerCase()} ${tags.join(' ')} ${title.toLowerCase()} ${id.toLowerCase()}'.trim();
  final key = basis.isEmpty ? DateTime.now().millisecondsSinceEpoch.toString() : basis;
  final idx = (key.hashCode & 0x7fffffff) % pool.length;
  return pool[idx];
}

  Map<String, dynamic> _recipeToJson(Recipe recipe) {
    return {
      'id': recipe.id,
      'title': recipe.title,
      'description': recipe.description,
      'duration': recipe.duration,
      'servings': recipe.servings,
      'imageUrl': recipe.imageUrl,
      'tags': recipe.tags,
      'ingredients': recipe.ingredients,
      'steps': recipe.steps,
      'tips': recipe.tips,
      'calories': recipe.calories,
      'protein': recipe.protein,
      'sugar': recipe.sugar,
      'carbs': recipe.carbs,
    };
  }

  Recipe _recipeFromJson(Map<String, dynamic> json) {
    return Recipe(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      duration: (json['duration'] ?? '').toString(),
      servings: json['servings'] is int ? json['servings'] as int : 2,
      imageUrl: (json['imageUrl'] ?? '').toString(),
      tags: (json['tags'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
      ingredients: (json['ingredients'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
      steps: (json['steps'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
      tips: (json['tips'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
      calories: _toDouble(json['calories']),
      protein: _toDouble(json['protein']),
      sugar: _toDouble(json['sugar']),
      carbs: _toDouble(json['carbs']),
    );
  }

  double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }
}
