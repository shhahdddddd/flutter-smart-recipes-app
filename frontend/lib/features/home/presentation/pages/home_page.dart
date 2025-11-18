import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../routes/app_routes.dart';
import '../models/recipe.dart';
import '../widgets/home_drawer.dart';
import '../controllers/home_controller.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static Recipe _findRecipe(String id) {
    return recipesCatalog.firstWhere(
      (recipe) => recipe.id == id,
      orElse: () => recipesCatalog.first,
    );
  }

  static final _popularRecipes = [
    _RecipeCardData(
      recipe: _findRecipe('avocado-toast'),
      accentColor: const Color(0xFF7C4DFF),
    ),
    _RecipeCardData(
      recipe: _findRecipe('quinoa-bowl'),
      accentColor: const Color(0xFF00BFA6),
    ),
    _RecipeCardData(
      recipe: _findRecipe('salmon-teriyaki'),
      accentColor: const Color(0xFFFF8A65),
    ),
    _RecipeCardData(
      recipe: _findRecipe('chia-parfait'),
      accentColor: const Color(0xFFFFCA28),
    ),
  ];

  static const _categories = [
    'All',
    'Breakfast',
    'Lunch',
    'Dinner',
    'Dessert',
    'Vegan',
    'Gluten-Free',
  ];

  static const _sections = [
    _HomeShortcut(
      label: 'Smart Meal Suggestions',
      icon: Icons.insights_outlined,
      route: AppRoutes.smartMealSuggestions,
      description: 'Daily AI-powered picks tailored to you.',
    ),
    _HomeShortcut(
      label: 'Weekly Meal Planner',
      icon: Icons.calendar_month_outlined,
      route: AppRoutes.weeklyMealPlanner,
      description: 'Plan balanced meals for the whole week.',
    ),
    _HomeShortcut(
      label: 'My Health & Preferences',
      icon: Icons.favorite_outline,
      route: AppRoutes.healthPreferences,
      description: 'Update health conditions, allergies, and goals.',
    ),
    _HomeShortcut(
      label: 'Shopping List',
      icon: Icons.shopping_basket_outlined,
      route: AppRoutes.shoppingList,
      description: 'Auto-generated ingredients for your plans.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      drawer: const HomeDrawer(),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Builder(
                          builder: (context) {
                            return IconButton(
                              icon: const Icon(Icons.menu_rounded),
                              onPressed: () => Scaffold.of(context).openDrawer(),
                            );
                          },
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hi there 👋',
                                style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey.shade700),
                              ),
                              Text(
                                'Find your next favorite recipe',
                                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        const CircleAvatar(
                          radius: 22,
                          backgroundColor: Color(0xFF7C4DFF),
                          child: Icon(Icons.person, color: Colors.white),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _SearchField(theme: theme),
                    const SizedBox(height: 24),
                    Obx(() {
                      final home = Get.find<HomeController>();
                      final recs = home.recommendedRecipes;
                      final query = home.searchQuery.value.trim().toLowerCase();
                      final filtered = query.isEmpty
                          ? recs
                          : recs.where((r) {
                              final title = r.title.toLowerCase();
                              final desc = r.description.toLowerCase();
                              final tags = r.tags.map((t) => t.toLowerCase()).join(' ');
                              return title.contains(query) || desc.contains(query) || tags.contains(query);
                            }).toList();
                      final title = recs.isNotEmpty ? 'Recommended For You' : 'Popular Recipes';
                      final base = filtered.isNotEmpty ? filtered : recs;
                      final items = base.isNotEmpty
                          ? base.take(10).toList().asMap().entries.map((e) {
                              final idx = e.key;
                              final recipe = e.value;
                              final colors = [
                                const Color(0xFF7C4DFF),
                                const Color(0xFF00BFA6),
                                const Color(0xFFFF8A65),
                                const Color(0xFFFFCA28),
                              ];
                              return _RecipeCardData(recipe: recipe, accentColor: colors[idx % colors.length]);
                            }).toList()
                          : _popularRecipes;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 320,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: items.length,
                              separatorBuilder: (_, __) => const SizedBox(width: 16),
                              itemBuilder: (context, index) {
                                final data = items[index];
                                return _RecipeCard(data: data);
                              },
                            ),
                          ),
                        ],
                      );
                    }),
                    const SizedBox(height: 24),
                    Text(
                      'Category',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 42,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _categories.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          final text = _categories[index];
                          final isSelected = index == 0;
                          return InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () {
                              Get.toNamed(
                                AppRoutes.category,
                                arguments: {'category': text},
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected ? const Color(0xFF7C4DFF) : Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  if (!isSelected)
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.05),
                                      blurRadius: 10,
                                      offset: const Offset(0, 6),
                                    ),
                                ],
                              ),
                              child: Text(
                                text,
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: isSelected ? Colors.white : Colors.black87,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Plan & Manage',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: SliverList.separated(
                itemCount: _sections.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final shortcut = _sections[index];
                  return _ShortcutCard(shortcut: shortcut);
                },
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _QuickAccessGrid(theme: theme),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class _SearchField extends StatelessWidget {
  const _SearchField({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return TextField(
      decoration: InputDecoration(
        hintText: 'Search recipes...',
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
      style: theme.textTheme.bodyMedium,
      onChanged: (value) {
        final home = Get.find<HomeController>();
        home.setSearchQuery(value);
      },
    );
  }
}

class _RecipeCardData {
  const _RecipeCardData({
    required this.recipe,
    required this.accentColor,
  });

  final Recipe recipe;
  final Color accentColor;
}

class _RecipeCard extends StatelessWidget {
  const _RecipeCard({required this.data});

  final _RecipeCardData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: () => Get.toNamed(AppRoutes.recipeDetail, arguments: data.recipe),
      borderRadius: BorderRadius.circular(24),
      child: Ink(
        width: 240,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              child: AspectRatio(
                aspectRatio: 16 / 11,
                child: Image.network(
                  data.recipe.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
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
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.recipe.title,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.timer_outlined, size: 18, color: data.accentColor),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          data.recipe.duration,
                          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
  }
}

class _HomeShortcut {
  const _HomeShortcut({
    required this.label,
    required this.icon,
    required this.route,
    required this.description,
  });

  final String label;
  final IconData icon;
  final String route;
  final String description;
}

class _ShortcutCard extends StatelessWidget {
  const _ShortcutCard({required this.shortcut});

  final _HomeShortcut shortcut;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: () => Get.toNamed(shortcut.route),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              height: 52,
              width: 52,
              decoration: BoxDecoration(
                color: const Color(0xFF7C4DFF).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(shortcut.icon, color: const Color(0xFF7C4DFF)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    shortcut.label,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    shortcut.description,
                    style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 18, color: Colors.grey.shade500),
          ],
        ),
      ),
    );
  }
}

class _QuickAccessGrid extends StatelessWidget {
  const _QuickAccessGrid({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final items = const [
      _HomeShortcut(
        label: 'Recipe Library',
        icon: Icons.menu_book,
        route: AppRoutes.recipes,
        description: 'Browse 120+ curated dishes',
      ),
      _HomeShortcut(
        label: 'Saved Recipes',
        icon: Icons.bookmark_added_outlined,
        route: AppRoutes.favorites,
        description: 'Your bookmarked favorites',
      ),
      _HomeShortcut(
        label: 'Shopping List',
        icon: Icons.shopping_cart_checkout_outlined,
        route: AppRoutes.shoppingList,
        description: 'Groceries ready to shop',
      ),
      _HomeShortcut(
        label: 'Account Settings',
        icon: Icons.settings_suggest_outlined,
        route: AppRoutes.settings,
        description: 'Personalize your experience',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Access',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final isTwoColumn = constraints.maxWidth > 500;
            return Wrap(
              spacing: 16,
              runSpacing: 16,
              children: items.map((item) {
                final width = (constraints.maxWidth - (isTwoColumn ? 16 : 0)) / (isTwoColumn ? 2 : 1);
                return SizedBox(
                  width: width,
                  child: _ShortcutCard(shortcut: item),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}
