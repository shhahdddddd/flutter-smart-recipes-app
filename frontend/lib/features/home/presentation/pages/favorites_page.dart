import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../../../../core/utils/constants.dart';
import '../../../../injection_container.dart' as di;
import '../../../auth/domain/repositories/auth_repository.dart';
import '../models/recipe.dart';
import '../../../../routes/app_routes.dart';

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

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F4FB),
      appBar: AppBar(
        title: const Text('Favorites & Saved Recipes'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: Builder(
        builder: (context) {
          final client = di.sl<http.Client>();
          final authRepo = di.sl<AuthRepository>();
          final session = authRepo.getCachedSession();
          if (session == null) {
            return const _EmptyState();
          }
          return FutureBuilder<http.Response>(
            future: client.get(
              Uri.parse('${AppConstants.baseUrl}/users/favorites'),
              headers: {'Authorization': 'Bearer ${session.token}'},
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              final resp = snapshot.data;
              if (resp == null || resp.statusCode != 200) {
                return const _EmptyState();
              }
              final decoded = jsonDecode(resp.body) as Map<String, dynamic>;
              final List<dynamic> data = decoded['data'] as List<dynamic>? ?? [];
              if (data.isEmpty) {
                return const _EmptyState();
              }

              final favorites = data.whereType<Map<String, dynamic>>().map((map) {
                final ingredientList = (map['ingredients'] as List<dynamic>? ?? []);
                final ingredients = ingredientList.map((ing) {
                  if ( ing is Map<String, dynamic>) {
                    final name = (ing['name'] ?? '').toString();
                    final quantity = (ing['quantity'] ?? '').toString();
                    final note = (ing['note'] ?? '').toString();
                    final parts = <String>[];
                    if (quantity.isNotEmpty) parts.add(quantity);
                    if (name.isNotEmpty) parts.add(name);
                    if (note.isNotEmpty) parts.add('($note)');
                    return parts.join(' ');
                  }
                  return ing.toString();
                }).where((s) => s.trim().isNotEmpty).toList();

                final instructions = (map['instructions'] as List<dynamic>? ?? [])
                    .map((s) => (s is Map<String, dynamic> ? s['description'] : s)?.toString() ?? '')
                    .where((s) => s.trim().isNotEmpty)
                    .toList();

                final cookingTime = map['cookingTime'];
                final duration = cookingTime == null ? 'N/A' : '$cookingTime min';

                final tags = (map['tags'] as List<dynamic>? ?? []).map((t) => t.toString()).toList();
                final id = (map['_id'] ?? '').toString();
                final title = (map['title'] ?? '').toString();
                final category = (map['category'] ?? '').toString();
                final rawImage = (map['image'] ?? '').toString();
                final imageUrl = _pickImage(rawImage, tags, category, title, id);

                return Recipe(
                  id: id,
                  title: title,
                  description: (map['description'] ?? '').toString(),
                  duration: duration,
                  servings: 2,
                  imageUrl: imageUrl,
                  tags: tags,
                  ingredients: ingredients,
                  steps: instructions,
                );
              }).toList();

              if (favorites.isEmpty) {
                return const _EmptyState();
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: favorites.length,
                itemBuilder: (context, index) {
                  final recipe = favorites[index];
                  return InkWell(
                    onTap: () => Get.toNamed(AppRoutes.recipeDetail, arguments: recipe),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
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
                                    width: 80,
                                    height: 80,
                                    color: Colors.grey.shade200,
                                    alignment: Alignment.center,
                                    child: const Icon(Icons.favorite, color: Color(0xFFFF7043)),
                                  )
                                : Image.network(
                                    recipe.imageUrl,
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        width: 80,
                                        height: 80,
                                        color: Colors.grey.shade200,
                                        alignment: Alignment.center,
                                        child: const Icon(Icons.broken_image_outlined, color: Colors.grey),
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
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 4,
                                  children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.timer_outlined, size: 16),
                                        const SizedBox(width: 4),
                                        Text(recipe.duration, style: theme.textTheme.bodySmall),
                                      ],
                                    ),
                                    for (final tag in recipe.tags)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF7C4DFF).withValues(alpha: 0.08),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          tag,
                                          style: theme.textTheme.labelSmall?.copyWith(color: const Color(0xFF5D35FF)),
                                        ),
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
                },
              );
            },
          );
      },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 120,
              width: 120,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(32),
              ),
              child: const Icon(Icons.favorite_border, size: 54, color: Color(0xFFFF7043)),
            ),
            const SizedBox(height: 24),
            Text(
              'No saved recipes yet',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Heart the recipes you love to build your personal cookbook.',
              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
