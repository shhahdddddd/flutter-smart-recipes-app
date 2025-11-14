import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../../../core/utils/constants.dart';
import '../../../../injection_container.dart' as di;
import '../../../auth/domain/entities/health_profile_input.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../../auth/domain/usecases/complete_health_profile.dart';
import '../models/recipe.dart';

class HomeController extends GetxController {
  HomeController({AuthRepository? repository, CompleteHealthProfile? completeHealthProfile, http.Client? client})
      : _repository = repository ?? di.sl<AuthRepository>(),
        _completeHealthProfile = completeHealthProfile ?? di.sl<CompleteHealthProfile>(),
        _client = client ?? di.sl<http.Client>();

  final AuthRepository _repository;
  final CompleteHealthProfile _completeHealthProfile;
  final http.Client _client;

  final Rxn<User> user = Rxn<User>();
  final RxBool isSaving = false.obs;

  final RxList<Recipe> recommendedRecipes = <Recipe>[].obs;
  final RxBool isLoadingRecommendations = false.obs;

  @override
  void onInit() {
    super.onInit();
    _loadUser();
    _loadRecommendedRecipes();
  }

  void _loadUser() {
    final session = _repository.getCachedSession();
    user.value = session?.user;
  }

  void updateUser(User updated) {
    user.value = updated;
  }

  Future<String?> saveHealthProfile(HealthProfileInput input) async {
    final session = _repository.getCachedSession();
    if (session == null) {
      return 'Your session has expired. Please log in again.';
    }

    isSaving.value = true;
    try {
      final result = await _completeHealthProfile(
        token: session.token,
        input: input,
      );

      String? failureMessage;
      result.fold(
        (failure) => failureMessage = failure.message,
        (updatedUser) => user.value = updatedUser,
      );

      return failureMessage;
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> _loadRecommendedRecipes() async {
    final session = _repository.getCachedSession();
    if (session == null) return;

    isLoadingRecommendations.value = true;
    try {
      final resp = await _client.get(
        Uri.parse('${AppConstants.baseUrl}/users/recipes'),
        headers: {'Authorization': 'Bearer ${session.token}'},
      );
      List<Recipe> parsed = [];
      if (resp.statusCode == 200) {
        final body = resp.body;
        final decoded = jsonDecode(body) as Map<String, dynamic>;
        final data = (decoded['data'] as List<dynamic>? ?? []);
        parsed = data.whereType<Map<String, dynamic>>().map((map) {
          final ingredientList = (map['ingredients'] as List<dynamic>? ?? []);
          final ingredients = ingredientList
              .map((ing) => ((ing as Map<String, dynamic>)['quantity']?.toString() ?? '').trim())
              .toList();
          final instructions = (map['instructions'] as List<dynamic>? ?? [])
              .map((s) => (s as Map<String, dynamic>)['description']?.toString() ?? '')
              .toList();
          final cookingTime = map['cookingTime'];
          final duration = cookingTime == null ? 'N/A' : '$cookingTime min';
          final tags = (map['tags'] as List<dynamic>? ?? []).map((t) => t.toString()).toList();
          return Recipe(
            id: (map['_id'] ?? '').toString(),
            title: (map['title'] ?? '').toString(),
            description: (map['description'] ?? '').toString(),
            duration: duration,
            servings: 2,
            imageUrl: (map['image'] ?? '').toString(),
            tags: tags,
            ingredients: ingredients,
            steps: instructions,
            tips: const [],
          );
        }).toList();
      }

      if (parsed.isEmpty && user.value != null) {
        final u = user.value!;
        final lifestyle = u.lifestylePreferences.map((e) => e.toLowerCase()).toList();
        List<String> defaultIngredients = ['rice', 'vegetables', 'olive oil'];
        if (lifestyle.contains('vegan') || lifestyle.contains('vegetarian')) {
          defaultIngredients = ['tofu', 'beans', 'vegetables'];
        } else if (lifestyle.contains('gluten-free')) {
          defaultIngredients = ['rice', 'potatoes', 'vegetables'];
        } else if (lifestyle.contains('halal')) {
          defaultIngredients = ['chicken', 'rice', 'vegetables'];
        }

        final prefs = {
          'diet': lifestyle.isNotEmpty ? lifestyle.first : null,
          'allergies': [...u.allergies, ...u.intolerances],
          'excludedIngredients': u.optionalTags,
          'healthGoals': [...u.weightManagementGoals, ...u.dietaryGoals],
          'conditions': [...u.conditions, ...u.chronicConditions],
          'lifestylePreferences': u.lifestylePreferences,
        };

        await _client.post(
          Uri.parse('${AppConstants.baseUrl}/ai/generate-recipes'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${session.token}',
          },
          body: jsonEncode({
            'ingredients': defaultIngredients,
            'preferences': prefs,
          }),
        );

        final second = await _client.get(
          Uri.parse('${AppConstants.baseUrl}/users/recipes'),
          headers: {'Authorization': 'Bearer ${session.token}'},
        );
        if (second.statusCode == 200) {
          final decoded = jsonDecode(second.body) as Map<String, dynamic>;
          final data = (decoded['data'] as List<dynamic>? ?? []);
          parsed = data.whereType<Map<String, dynamic>>().map((map) {
            final ingredientList = (map['ingredients'] as List<dynamic>? ?? []);
            final ingredients = ingredientList
                .map((ing) => ((ing as Map<String, dynamic>)['quantity']?.toString() ?? '').trim())
                .toList();
            final instructions = (map['instructions'] as List<dynamic>? ?? [])
                .map((s) => (s as Map<String, dynamic>)['description']?.toString() ?? '')
                .toList();
            final cookingTime = map['cookingTime'];
            final duration = cookingTime == null ? 'N/A' : '$cookingTime min';
            final tags = (map['tags'] as List<dynamic>? ?? []).map((t) => t.toString()).toList();
            return Recipe(
              id: (map['_id'] ?? '').toString(),
              title: (map['title'] ?? '').toString(),
              description: (map['description'] ?? '').toString(),
              duration: duration,
              servings: 2,
              imageUrl: (map['image'] ?? '').toString(),
              tags: tags,
              ingredients: ingredients,
              steps: instructions,
              tips: const [],
            );
          }).toList();
        }
      }

      // Shuffle to provide varied "Recommended For You" items on each load
      parsed.shuffle();
      // Optionally limit to a reasonable number
      if (parsed.length > 20) {
        parsed = parsed.sublist(0, 20);
      }
      recommendedRecipes.value = parsed;
    } catch (_) {
      recommendedRecipes.clear();
    } finally {
      isLoadingRecommendations.value = false;
    }
  }
}
