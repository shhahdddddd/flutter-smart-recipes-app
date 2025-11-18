import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/recipes_controller.dart';
import '../controllers/smart_meal_suggestions_controller.dart';
import '../controllers/home_controller.dart';
import '../models/recipe.dart';
import '../../../../routes/app_routes.dart';

String _difficultyFor(Recipe r) {
  final match = RegExp(r'(\d+)').firstMatch(r.duration);
  final minutes = int.tryParse(match?.group(1) ?? '0') ?? 0;
  if (minutes == 0) return 'medium';
  if (minutes <= 15) return 'easy';
  if (minutes <= 30) return 'medium';
  return 'hard';
}

int _healthScoreFor(Recipe r) {
  int score = 50;
  final tags = r.tags.map((t) => t.toLowerCase()).toList();
  if (tags.any((t) => t.contains('healthy') || t.contains('heart') || t.contains('omega') || t.contains('high protein'))) {
    score += 20;
  }
  if (tags.any((t) => t.contains('dessert') || t.contains('sugar'))) {
    score -= 10;
  }
  if (score < 0) score = 0;
  if (score > 100) score = 100;
  return score;
}

String _healthBenefitsFor(Recipe r) {
  final tags = r.tags.map((t) => t.toLowerCase()).toList();
  final ingredients = r.ingredients.map((i) => i.toLowerCase()).toList();
  final benefits = <String>[];
  if (tags.any((t) => t.contains('omega'))) benefits.add('Supports heart health');
  if (tags.any((t) => t.contains('high protein'))) benefits.add('High protein for recovery');
  if (tags.any((t) => t.contains('heart'))) benefits.add('Heart-friendly');
  if (tags.any((t) => t.contains('vegetarian') || t.contains('vegan'))) benefits.add('Plant-based, fiber-rich');
  if (ingredients.any((i) => i.contains('spinach') || i.contains('kale') || i.contains('berries'))) benefits.add('Rich in vitamins');
  if (ingredients.any((i) => i.contains('oats') || i.contains('beans') || i.contains('quinoa') || i.contains('whole'))) benefits.add('Good source of fiber');
  if (ingredients.any((i) => i.contains('turmeric') || i.contains('ginger'))) benefits.add('Anti-inflammatory');
  return benefits.take(3).join(' • ');
}

class CategoryPage extends StatefulWidget {
  const CategoryPage({super.key});

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  late final RecipesController _recipesController;
  late final String _category;
  bool _isPreparing = true;

  @override
  void initState() {
    super.initState();
    _recipesController = Get.find<RecipesController>();
    final args = Get.arguments;
    _category = (args is Map && args['category'] != null)
        ? args['category'].toString()
        : 'All';

    // Simulate "preparing" state for UX (1.5 seconds)
    Timer(const Duration(milliseconds: 1500), () async {
      if (mounted) {
        setState(() {
          _isPreparing = false;
        });
        await _recipesController.ensureMinimumForCategory(_category, min: 10);
      }
    });
  }

  List<Recipe> _filterByCategory(List<Recipe> all) {
    final lower = _category.toLowerCase();
    final home = Get.find<HomeController>();
    final user = home.user.value;

    bool matchesCategory(Recipe r) {
      final tags = r.tags.map((t) => t.toLowerCase()).toList();
      final title = r.title.toLowerCase();
      final desc = r.description.toLowerCase();

      if (lower == 'all') return true;
      if (lower.contains('breakfast')) return tags.any((t) => t.contains('breakfast'));
      if (lower.contains('lunch')) return tags.any((t) => t.contains('lunch'));
      if (lower.contains('dinner')) return tags.any((t) => t.contains('dinner'));
      if (lower.contains('dessert')) return tags.any((t) => t.contains('dessert') || t.contains('sweet'));

      if (tags.any((t) => t.contains(lower)) || (!lower.contains('dessert') && (title.contains(lower) || desc.contains(lower)))) return true;
      if (lower.contains('gluten')) return !r.ingredients.any((i) => i.toLowerCase().contains('wheat'));
      if (lower.contains('vegetarian')) return tags.any((t) => t.contains('vegetarian') || t.contains('vegan'));
      if (lower.contains('vegan')) return tags.any((t) => t.contains('vegan'));
      if (lower.contains('fast')) {
        final match = RegExp(r'(\d+)').firstMatch(r.duration);
        final minutes = int.tryParse(match?.group(1) ?? '0') ?? 0;
        return minutes > 0 && minutes <= 20;
      }
      if (lower.contains('healthy')) {
        return tags.any((t) => t.contains('healthy') || t.contains('heart') || t.contains('omega') || t.contains('high protein'));
      }
      if (lower.contains('cheap') || lower.contains('budget')) {
        return tags.any((t) => t.contains('cheap') || t.contains('budget'));
      }
      if (lower.contains('zero waste')) return tags.any((t) => t.contains('zero waste'));

      return false;
    }

    bool respectsUser(Recipe r) {
      if (user == null) return true;
      final allergens = [...user.allergies, ...user.intolerances].map((a) => a.toLowerCase());
      for (final a in allergens) {
        if (a.isNotEmpty && r.ingredients.any((i) => i.toLowerCase().contains(a))) return false;
      }
      final lifestyle = user.lifestylePreferences.map((e) => e.toLowerCase()).toList();
      if (lifestyle.contains('vegan')) return r.tags.any((t) => t.toLowerCase().contains('vegan'));
      if (lifestyle.contains('vegetarian')) return r.tags.any((t) => t.toLowerCase().contains('vegetarian'));
      return true;
    }

    return all.where((r) => matchesCategory(r) && respectsUser(r)).toList();
  }

  List<Recipe> _dedupe(List<Recipe> source) {
    final seen = <String, Recipe>{};
    for (final r in source) {
      final key = r.title.trim().toLowerCase();
      if (key.isEmpty) continue;
      seen.putIfAbsent(key, () => r);
    }
    return seen.values.toList();
  }

  String _categoryDescription() {
    final c = _category.toLowerCase();
    if (c.contains('healthy')) {
      return 'Balanced, low calorie choices that support wellness.';
    }
    if (c.contains('fast')) {
      return 'Quick meals with simple steps, ready in under 15–20 minutes.';
    }
    if (c.contains('cheap') || c.contains('budget')) {
      return 'Low cost meals using easy-to-find ingredients.';
    }
    if (c.contains('vegetarian')) {
      return 'Plant-based recipes focusing on vegetables, grains, and legumes.';
    }
    if (c.contains('zero waste')) {
      return 'Smart recipes designed to use ingredients efficiently.';
    }
    if (c.contains('breakfast')) return 'Start your day right with energizing breakfasts.';
    if (c.contains('lunch')) return 'Midday meals that keep you going.';
    if (c.contains('dinner')) return 'Comforting dishes for the evening.';
    if (c.contains('dessert')) return 'Sweet treats and light desserts.';
    return '';
  }

  

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(_category),
      ),
      body: Obx(() {
        final home = Get.find<HomeController>();
        final combined = <Recipe>[]
          ..addAll(home.recommendedRecipes)
          ..addAll(_recipesController.recipes);
        final all = _dedupe(combined);
        final isLoadingRecipes = _recipesController.isLoading.value;

        if (_isPreparing || (isLoadingRecipes && all.isEmpty)) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  'Preparing ${_category.toLowerCase()} picks for you...',
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        if (all.isEmpty) {
          return Center(
            child: Text(
              'No recipes available yet.',
              style: theme.textTheme.bodyMedium,
            ),
          );
        }

        final filtered = _filterByCategory(all.toList());
        var display = filtered;
        if (display.isEmpty) {
          final fallback = _filterByCategory(recipesCatalog.toList());
          display = fallback.isNotEmpty ? fallback : (all.isNotEmpty ? all.toList() : recipesCatalog.toList());
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: display.length + 1,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            if (index == 0) {
              final desc = _categoryDescription();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_category, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                  if (desc.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(desc, style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600)),
                  ],
                ],
              );
            }
            final recipe = display[index - 1];
            return _CategoryRecipeTile(recipe: recipe);
          },
        );
      }),
    );
  }
}

class _CategoryRecipeTile extends StatelessWidget {
  const _CategoryRecipeTile({required this.recipe});

  final Recipe recipe;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => Get.toNamed(AppRoutes.recipeDetail, arguments: recipe),
      child: Ink(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: (recipe.imageUrl.trim().isEmpty)
                  ? Container(
                      height: 80,
                      width: 100,
                      color: Colors.grey.shade200,
                      alignment: Alignment.center,
                      child: const Icon(Icons.restaurant_menu, color: Colors.grey),
                    )
                  : SizedBox(
                      height: 80,
                      width: 100,
                      child: Image.network(
                        recipe.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey.shade200,
                            alignment: Alignment.center,
                            child: const Icon(Icons.broken_image_outlined, color: Colors.grey),
                          );
                        },
                      ),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe.title,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    recipe.description,
                    style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Builder(builder: (context) {
                    final benefits = _healthBenefitsFor(recipe);
                    if (benefits.isEmpty) return const SizedBox.shrink();
                    return Text(
                      benefits,
                      style: theme.textTheme.bodySmall?.copyWith(color: const Color(0xFF00BFA6)),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    );
                  }),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Wrap(
                          spacing: 12,
                          runSpacing: 6,
                          children: [
                            Row(children: [
                              const Icon(Icons.timer_outlined, size: 16),
                              const SizedBox(width: 4),
                              Text(recipe.duration, style: theme.textTheme.bodySmall),
                            ]),
                            Row(children: [
                              const Icon(Icons.speed_outlined, size: 16),
                              const SizedBox(width: 4),
                              Text(_difficultyFor(recipe), style: theme.textTheme.bodySmall),
                            ]),
                            Row(children: [
                              const Icon(Icons.health_and_safety_outlined, size: 16),
                              const SizedBox(width: 4),
                              Text('Health ${_healthScoreFor(recipe)}', style: theme.textTheme.bodySmall),
                            ]),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Wrap(
                        spacing: 4,
                        children: [
                          IconButton(
                            tooltip: 'Save',
                            icon: const Icon(Icons.favorite_border),
                            onPressed: () => Get.find<RecipesController>().addToFavorites(recipe),
                          ),
                          IconButton(
                            tooltip: 'Add to Shopping',
                            icon: const Icon(Icons.add_shopping_cart_outlined),
                            onPressed: () => Get.find<SmartMealSuggestionsController>()
                                .addIngredientsToShoppingList(recipe.ingredients),
                          ),
                          IconButton(
                            tooltip: 'Similar',
                            icon: const Icon(Icons.auto_awesome_outlined),
                            onPressed: () => Get.find<RecipesController>().generateSimilar(recipe),
                          ),
                          IconButton(
                            tooltip: 'Add to Planner',
                            icon: const Icon(Icons.calendar_month_outlined),
                            onPressed: () => Get.toNamed(AppRoutes.weeklyMealPlanner, arguments: {'recipe': recipe}),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
