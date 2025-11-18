import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../routes/app_routes.dart';
import '../controllers/recipes_controller.dart';
import '../models/recipe.dart';

class RecipesPage extends StatelessWidget {
  const RecipesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = Get.find<RecipesController>();

    return Scaffold(
      backgroundColor: const Color(0xFFF6F4FB),
      appBar: AppBar(
        title: const Text('Recipes Library'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.error.value.isNotEmpty) {
          return Center(child: Text('Error: ${controller.error.value}'));
        }

        final recipes = [...controller.recipes, ...recipesCatalog];
        
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: 'Search in ${recipes.length}+ recipes',
                  fillColor: Colors.white,
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                itemCount: recipes.length,
                itemBuilder: (context, index) {
                  final recipe = recipes[index];
                  return _RecipeListTile(recipe: recipe, theme: theme);
                },
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _RecipeListTile extends StatelessWidget {
  const _RecipeListTile({required this.recipe, required this.theme});

  final Recipe recipe;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Get.toNamed(
        AppRoutes.recipeDetail,
        arguments: recipe,
      ),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        margin: const EdgeInsets.only(bottom: 18),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 18,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: (recipe.imageUrl.trim().isEmpty)
                  ? Container(
                      width: 90,
                      height: 90,
                      color: Colors.grey.shade200,
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.restaurant_menu,
                        color: Colors.grey,
                      ),
                    )
                  : Image.network(
                      recipe.imageUrl,
                      width: 90,
                      height: 90,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 90,
                          height: 90,
                          color: Colors.grey.shade200,
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.broken_image_outlined,
                            color: Colors.grey,
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe.title,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    recipe.description,
                    style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _Chip(icon: Icons.schedule_outlined, label: recipe.duration),
                      _Chip(icon: Icons.restaurant_outlined, label: '${recipe.servings} servings'),
                      for (final tag in recipe.tags) _Chip(icon: Icons.local_offer_outlined, label: tag),
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

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF7C4DFF).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF7C4DFF)),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: const Color(0xFF5D35FF),
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}
