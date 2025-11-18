import 'package:get/get.dart';

import '../features/auth/presentation/bindings/auth_binding.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/auth/presentation/pages/onboarding_page.dart';
import '../features/auth/presentation/pages/sign_up_page.dart';
import '../features/home/presentation/bindings/home_binding.dart';
import '../features/home/presentation/pages/favorites_page.dart';
import '../features/home/presentation/pages/edit_profile_page.dart';
import '../features/home/presentation/pages/change_password_page.dart';
import '../features/home/presentation/pages/health_preferences_page.dart';
import '../features/home/presentation/pages/home_page.dart';
import '../features/home/presentation/pages/manage_account_page.dart';
import '../features/home/presentation/pages/recipe_detail_page.dart';
import '../features/home/presentation/pages/category_page.dart';
import '../features/home/presentation/pages/recipes_page.dart';
import '../features/home/presentation/pages/settings_page.dart';
import '../features/home/presentation/pages/shopping_list_page.dart';
import '../features/home/presentation/pages/smart_meal_suggestions_page.dart';
import '../features/home/presentation/pages/weekly_meal_planner_page.dart';
import 'app_routes.dart';

class AppPages {
  static final pages = <GetPage<dynamic>>[
    GetPage(
      name: AppRoutes.onboarding,
      page: () => const OnboardingPage(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: AppRoutes.signUp,
      page: () => SignUpPage(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: AppRoutes.login,
      page: () => LoginPage(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: AppRoutes.home,
      page: () => const HomePage(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: AppRoutes.manageAccount,
      page: () => const ManageAccountPage(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: AppRoutes.editProfile,
      page: () => const EditProfilePage(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: AppRoutes.security,
      page: () => const ChangePasswordPage(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: AppRoutes.smartMealSuggestions,
      page: () => const SmartMealSuggestionsPage(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: AppRoutes.weeklyMealPlanner,
      page: () => const WeeklyMealPlannerPage(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: AppRoutes.healthPreferences,
      page: () => const HealthPreferencesPage(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: AppRoutes.recipes,
      page: () => const RecipesPage(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: AppRoutes.category,
      page: () => const CategoryPage(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: AppRoutes.recipeDetail,
      page: () => const RecipeDetailPage(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: AppRoutes.favorites,
      page: () => const FavoritesPage(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: AppRoutes.shoppingList,
      page: () => const ShoppingListPage(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: AppRoutes.settings,
      page: () => const SettingsPage(),
      binding: HomeBinding(),
    ),
  ];
}
