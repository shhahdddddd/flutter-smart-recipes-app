import 'dart:convert';

import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../../../../core/utils/constants.dart';
import '../../../../injection_container.dart' as di;
import '../../../auth/domain/repositories/auth_repository.dart';
import '../models/recipe.dart';

class RecipesController extends GetxController {
  final AuthRepository _authRepository = di.sl<AuthRepository>();
  
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

          return Recipe(
            id: (map['_id'] ?? '').toString(),
            title: (map['title'] ?? '').toString(),
            description: (map['description'] ?? '').toString(),
            duration: duration,
            servings: 2,
            imageUrl: (map['image'] ?? '').toString(),
            tags: tags,
            ingredients: ingredients,
            steps: steps,
            tips: const [],
          );
        }).toList();

        recipes.value = parsed;
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
    loadRecipes();
    super.onInit();
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
}
