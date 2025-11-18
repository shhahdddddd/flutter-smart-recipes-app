import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'injection_container.dart' as di;
import 'features/auth/presentation/bindings/auth_binding.dart';
import 'routes/app_routes.dart';
import 'routes/app_pages.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await di.init();

  runApp(const RecipeManagerApp());
}

class RecipeManagerApp extends StatelessWidget {
  const RecipeManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Recipe Manager',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF7C4DFF),
          secondary: Color(0xFFE040FB),
          background: Color(0xFFF6F4FB),
        ),
        scaffoldBackgroundColor: const Color(0xFFF6F4FB),
        textTheme: GoogleFonts.poppinsTextTheme(),
      ),
      darkTheme: ThemeData(
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF7C4DFF),
          secondary: Color(0xFFE040FB),
          background: Color(0xFF121212),
        ),
        scaffoldBackgroundColor: const Color(0xFF121212),
        textTheme: GoogleFonts.poppinsTextTheme(),
      ),
      themeMode: ThemeMode.light,
      initialRoute: AppRoutes.onboarding,
      initialBinding: AuthBinding(),
      getPages: AppPages.pages,
    );
  }
}
