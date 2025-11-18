import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../routes/app_routes.dart';
import '../../domain/entities/health_profile_input.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/login_user.dart';
import '../../domain/usecases/register_user.dart';
import '../../../../injection_container.dart' as di;

class AuthController extends GetxController {
  AuthController({
    required this.registerUser,
    required this.loginUser,
  });

  final RegisterUser registerUser;
  final LoginUser loginUser;

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final conditionsController = TextEditingController();
  final notesController = TextEditingController();

  final registerFormKey = GlobalKey<FormState>();
  final loginFormKey = GlobalKey<FormState>();

  final isLoading = false.obs;
  final hasHealthIssues = false.obs;
  final obscurePassword = true.obs;

  void setHasHealthIssues(bool value) {
    hasHealthIssues.value = value;
    if (!value) {
      conditionsController.clear();
      notesController.clear();
    }
  }

  void togglePasswordVisibility() {
    obscurePassword.value = !obscurePassword.value;
  }

  Future<void> register() async {
    if (!(registerFormKey.currentState?.validate() ?? false)) {
      return;
    }

    isLoading.value = true;

    final conditions = hasHealthIssues.value
        ? conditionsController.text
            .split(',')
            .map((condition) => condition.trim())
            .where((condition) => condition.isNotEmpty)
            .toList()
        : <String>[];

    final profileInput = HealthProfileInput(
      hasHealthIssues: hasHealthIssues.value,
      conditions: conditions,
      notes: notesController.text.trim().isEmpty
          ? null
          : notesController.text.trim(),
      preferencesCompleted: false,
    );

    final result = await registerUser(
      name: nameController.text.trim(),
      email: emailController.text.trim(),
      password: passwordController.text,
      healthProfile: profileInput,
    );

    result.fold(
      (failure) {
        Get.snackbar(
          'Erreur',
          failure.message,
          snackPosition: SnackPosition.BOTTOM,
        );
      },
      (session) {
        Get.snackbar(
          'Bienvenue',
          'Connexion réussie pour ${session.user.name}',
          snackPosition: SnackPosition.BOTTOM,
        );
        resetForms();
        Get.offAllNamed(AppRoutes.home);
      },
    );

    isLoading.value = false;
  }

  Future<void> login() async {
    if (!(loginFormKey.currentState?.validate() ?? false)) {
      return;
    }

    isLoading.value = true;

    final result = await loginUser(
      email: emailController.text.trim(),
      password: passwordController.text,
    );

    result.fold(
      (failure) {
        Get.snackbar(
          'Erreur',
          failure.message,
          snackPosition: SnackPosition.BOTTOM,
        );
      },
      (session) {
        Get.snackbar(
          'Bonjour',
          'Connexion réussie pour ${session.user.name}',
          snackPosition: SnackPosition.BOTTOM,
        );
        resetForms();
        Get.offAllNamed(AppRoutes.home);
      },
    );

    isLoading.value = false;
  }

  void resetForms() {
    nameController.clear();
    emailController.clear();
    passwordController.clear();
    conditionsController.clear();
    notesController.clear();
    hasHealthIssues.value = false;
  }

  Future<void> logout() async {
    await di.sl<AuthRepository>().logout();
    resetForms();
    Get.offAllNamed(AppRoutes.login);
  }
}
