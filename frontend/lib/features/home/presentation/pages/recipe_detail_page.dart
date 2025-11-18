import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/recipes_controller.dart';
import '../models/recipe.dart';

List<String> _computeHealthBenefits(Recipe r) {
  final tags = r.tags.map((t) => t.toLowerCase()).toList();
  final ingredients = r.ingredients.map((i) => i.toLowerCase()).toList();
  final out = <String>[];
  if (tags.any((t) => t.contains('omega'))) out.add('Supports heart health with omega-3');
  if (tags.any((t) => t.contains('high protein'))) out.add('High protein for muscle repair');
  if (tags.any((t) => t.contains('heart'))) out.add('Heart-friendly');
  if (tags.any((t) => t.contains('vegetarian') || t.contains('vegan'))) out.add('Plant-based and fiber-rich');
  if (ingredients.any((i) => i.contains('spinach') || i.contains('kale') || i.contains('berries'))) out.add('Rich in vitamins and antioxidants');
  if (ingredients.any((i) => i.contains('oats') || i.contains('beans') || i.contains('quinoa') || i.contains('whole'))) out.add('Good source of fiber');
  if (ingredients.any((i) => i.contains('turmeric') || i.contains('ginger'))) out.add('Anti-inflammatory properties');
  return out.take(6).toList();
}


class RecipeDetailPage extends StatelessWidget {
  const RecipeDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final recipe = Get.arguments is Recipe ? Get.arguments as Recipe : null;

    if (recipe == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Recipe Details')),
        body: const Center(child: Text('Recipe not found.')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF6F4FB),
      appBar: AppBar(
        title: Text(recipe.title),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Add to Favorites',
            icon: const Icon(Icons.favorite_border),
            onPressed: () => Get.find<RecipesController>().addToFavorites(recipe),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HeaderImage(imageUrl: recipe.imageUrl),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    children: [
                      _InfoChip(icon: Icons.access_time, label: recipe.duration),
                      _InfoChip(icon: Icons.restaurant, label: '${recipe.servings} servings'),
                      for (final tag in recipe.tags)
                        _InfoChip(icon: Icons.local_offer_outlined, label: tag),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    recipe.description,
                    style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey.shade800),
                  ),
                  const SizedBox(height: 24),
                  Builder(builder: (context) {
                    final benefits = _computeHealthBenefits(recipe);
                    if (benefits.isEmpty) return const SizedBox.shrink();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _SectionTitle(title: 'Health Benefits'),
                        const SizedBox(height: 12),
                        ...benefits.map((b) => _BulletItem(text: b, bullet: Icons.favorite_outline)).toList(),
                      ],
                    );
                  }),
                  const SizedBox(height: 28),
                  const _SectionTitle(title: 'Ingredients'),
                  const SizedBox(height: 12),
                  ...recipe.ingredients.map((ingredient) => _BulletItem(text: ingredient)),
                  const SizedBox(height: 28),
                  const _SectionTitle(title: 'Preparation'),
                  const SizedBox(height: 12),
                  ...recipe.steps
                      .asMap()
                      .entries
                      .map((entry) => _NumberedStep(index: entry.key + 1, text: entry.value)),
                  if (recipe.tips.isNotEmpty) ...[
                    const SizedBox(height: 28),
                    const _SectionTitle(title: 'Tips & Serving Ideas'),
                    const SizedBox(height: 12),
                    ...recipe.tips.map((tip) => _BulletItem(text: tip, bullet: Icons.lightbulb_outline)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderImage extends StatelessWidget {
  const _HeaderImage({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 10,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.grey.shade200,
                alignment: Alignment.center,
                child: const Icon(
                  Icons.broken_image_outlined,
                  size: 48,
                  color: Colors.grey,
                ),
              );
            },
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black38],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      title,
      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF7C4DFF).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF6736FF)),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: const Color(0xFF4F2CCB),
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

class _BulletItem extends StatelessWidget {
  const _BulletItem({required this.text, this.bullet = Icons.check_circle_outline});

  final String text;
  final IconData bullet;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(bullet, size: 18, color: const Color(0xFF7C4DFF)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade800),
            ),
          ),
        ],
      ),
    );
  }
}

class _NumberedStep extends StatelessWidget {
  const _NumberedStep({required this.index, required this.text});

  final int index;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 28,
            width: 28,
            decoration: BoxDecoration(
              color: const Color(0xFF7C4DFF).withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Text(
              '$index',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: const Color(0xFF4F2CCB),
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade800),
            ),
          ),
        ],
      ),
    );
  }
}
