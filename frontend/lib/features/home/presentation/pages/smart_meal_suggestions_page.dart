import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/smart_meal_suggestions_controller.dart';
import '../../../../routes/app_routes.dart';

class SmartMealSuggestionsPage extends StatelessWidget {
  const SmartMealSuggestionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<SmartMealSuggestionsController>();
    final ingredientsController = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Meal Suggestions'),
      ),
      body: Obx(() {
        final isLoading = controller.isLoading.value;
        final error = controller.errorMessage?.value ?? '';

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: ingredientsController,
                decoration: const InputDecoration(
                  labelText: 'Ingredients you have in your fridge (comma separated)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: isLoading
                      ? null
                      : () {
                          final raw = ingredientsController.text.trim();
                          final ingredients = raw
                              .split(',')
                              .map((e) => e.trim())
                              .where((e) => e.isNotEmpty)
                              .toList();
                          controller.fetchSmartSuggestions(ingredients);
                        },
                  icon: const Icon(Icons.insights_outlined),
                  label: const Text('Get Smart Suggestions'),
                ),
              ),
              const SizedBox(height: 16),
              if (isLoading) const LinearProgressIndicator(),
              if (error.isNotEmpty) ...[
                Text(
                  error,
                  style: const TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 12),
              ],
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (controller.recognizedIngredients.isNotEmpty) ...[
                        const Text(
                          'Recognized Ingredients',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: controller.recognizedIngredients
                              .map(
                                (item) => Chip(
                                  label: Text(item),
                                ),
                              )
                              .toList(),
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (controller.menu.value != null) ...[
                        const Text(
                          'Suggested Menu',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _MenuSummary(menu: controller.menu.value!),
                        const SizedBox(height: 16),
                      ],
                      if (controller.shoppingList.isNotEmpty) ...[
                        const Text(
                          'Shopping List (Missing Ingredients)',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: controller.shoppingList.map((item) {
                            final name = item['ingredient']?.toString() ?? 'Item';
                            final quantity = item['quantity']?.toString() ?? '';
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  const Icon(Icons.check_box_outline_blank, size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      quantity.isEmpty ? name : '$name - $quantity',
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            OutlinedButton(
                              onPressed: () => Get.offAllNamed(AppRoutes.home),
                              child: const Text('Annuler'),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton.icon(
                              onPressed: controller.isLoading.value
                                  ? null
                                  : () {
                                      controller.addMissingItemsToShoppingList();
                                      Get.snackbar(
                                        'Saved',
                                        'Shopping list saved',
                                        snackPosition: SnackPosition.BOTTOM,
                                      );
                                      Get.toNamed(AppRoutes.shoppingList);
                                    },
                              icon: const Icon(Icons.save_outlined),
                              label: const Text('Save'),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _MenuSummary extends StatelessWidget {
  const _MenuSummary({required this.menu});

  final Map<String, dynamic> menu;

  @override
  Widget build(BuildContext context) {
    final title = menu['title']?.toString() ?? 'AI Generated Menu';
    final description = menu['description']?.toString() ?? '';
    final meals = (menu['meals'] as List<dynamic>?) ?? const [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (description.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            description,
            style: const TextStyle(fontSize: 13),
          ),
        ],
        const SizedBox(height: 8),
        ...meals.take(5).map((rawMeal) {
          if (rawMeal is! Map<String, dynamic>) return const SizedBox.shrink();
          final recipe = rawMeal['recipe'] as Map<String, dynamic>?;
          final recipeTitle = recipe?['title']?.toString() ?? 'Meal';
          final mealType = rawMeal['mealType']?.toString() ?? '';
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                const Icon(Icons.restaurant_menu, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    mealType.isEmpty ? recipeTitle : '[$mealType] $recipeTitle',
                  ),
                ),
                IconButton(
                  tooltip: 'Save',
                  icon: const Icon(Icons.favorite_border),
                  onPressed: recipe == null
                      ? null
                      : () => Get.find<SmartMealSuggestionsController>()
                          .saveSuggestedRecipe(recipe),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}