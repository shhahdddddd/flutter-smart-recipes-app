import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/home_controller.dart';
import '../../../../routes/app_routes.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

class HomeDrawer extends StatelessWidget {
  const HomeDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomeController>();
    final theme = Theme.of(context);
    return Drawer(
      elevation: 0,
      backgroundColor: const Color(0xFFF6F4FB),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: const LinearGradient(
                  colors: [Color(0xFF7C4DFF), Color(0xFF00BFA6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: _DrawerHeader(controller: controller, theme: theme),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Navigation',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: Colors.grey.shade600,
                  letterSpacing: 0.4,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                children: const [
                  _DrawerItem(
                    icon: Icons.home_outlined,
                    label: 'Home',
                    route: AppRoutes.home,
                  ),
                  _DrawerItem(
                    icon: Icons.person_outline,
                    label: 'Manage Account',
                    route: AppRoutes.manageAccount,
                  ),
                  _DrawerItem(
                    icon: Icons.insights_outlined,
                    label: 'Smart Meal Suggestions',
                    route: AppRoutes.smartMealSuggestions,
                  ),
                  _DrawerItem(
                    icon: Icons.calendar_month_outlined,
                    label: 'Weekly Meal Planner',
                    route: AppRoutes.weeklyMealPlanner,
                  ),
                  _DrawerItem(
                    icon: Icons.favorite_outline,
                    label: 'My Health & Preferences',
                    route: AppRoutes.healthPreferences,
                  ),
                  _DrawerItem(
                    icon: Icons.menu_book_outlined,
                    label: 'Recipes',
                    route: AppRoutes.recipes,
                  ),
                  _DrawerItem(
                    icon: Icons.bookmark_border,
                    label: 'Favorites / Saved Recipes',
                    route: AppRoutes.favorites,
                  ),
                  _DrawerItem(
                    icon: Icons.shopping_cart_outlined,
                    label: 'Shopping List',
                    route: AppRoutes.shoppingList,
                  ),
                  _DrawerItem(
                    icon: Icons.settings_outlined,
                    label: 'Settings',
                    route: AppRoutes.settings,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: _LogoutTile(controller: controller),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerHeader extends StatelessWidget {
  const _DrawerHeader({
    required this.controller,
    required this.theme,
  });

  final HomeController controller;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Obx(
      () {
        final user = controller.user.value;

        return Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.white.withOpacity(0.15),
              backgroundImage: user?.photoUrl != null && user!.photoUrl!.isNotEmpty
                  ? NetworkImage(user.photoUrl!)
                  : null,
              child: (user?.photoUrl == null || (user!.photoUrl?.isEmpty ?? true))
                  ? const Icon(Icons.person, size: 32, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user?.name ?? 'Welcome',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.email ?? 'Tap Manage Account to complete your profile',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white.withOpacity(0.85),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
class _DrawerItem extends StatelessWidget {
  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.route,
  });

  final IconData icon;
  final String label;
  final String route;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isActive = Get.currentRoute == route;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell
        (
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Get.back();
          if (Get.currentRoute != route) {
            Get.toNamed(route);
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF7C4DFF).withOpacity(0.08) : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                height: 36,
                width: 36,
                decoration: BoxDecoration(
                  color: isActive
                      ? const Color(0xFF7C4DFF).withOpacity(0.16)
                      : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: isActive ? const Color(0xFF7C4DFF) : Colors.grey.shade700,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    color: isActive ? const Color(0xFF1A1A1A) : Colors.grey.shade800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LogoutTile extends StatelessWidget {
  const _LogoutTile({required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      leading: const Icon(Icons.logout, color: Color(0xFFB00020)),
      title: const Text('Log Out', style: TextStyle(fontWeight: FontWeight.w600)),
      subtitle: const Text('Sign out and return to login'),
      onTap: () async {
        final authController = Get.find<AuthController>();
        await authController.logout();
        controller.user.value = null;
      },
    );
  }
}
