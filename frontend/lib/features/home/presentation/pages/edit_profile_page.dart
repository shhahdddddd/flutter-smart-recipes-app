import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../../../../core/utils/constants.dart';
import '../../../../injection_container.dart' as di;
import '../../../auth/domain/entities/user.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../../../routes/app_routes.dart';
import '../controllers/home_controller.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  bool _isSaving = false;

  User _resolveUser() {
    final homeController = Get.find<HomeController>();
    final current = homeController.user.value;
    if (Get.arguments is User) {
      return Get.arguments as User;
    }
    if (current != null) return current;
    throw Exception('No user available for editing');
  }

  @override
  void initState() {
    super.initState();
    final user = _resolveUser();
    _nameController = TextEditingController(text: user.name);
    _emailController = TextEditingController(text: user.email);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    final authRepository = di.sl<AuthRepository>();
    final session = authRepository.getCachedSession();

    if (session == null) {
      Get.snackbar(
        'Session expired',
        'Please log in again to manage your account.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();

    if (name.isEmpty || email.isEmpty) {
      Get.snackbar(
        'Invalid data',
        'Name and email cannot be empty.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final response = await http.put(
        Uri.parse('${AppConstants.baseUrl}/users/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${session.token}',
        },
        body: jsonEncode({
          'name': name,
          'email': email,
        }),
      );

      if (response.statusCode == 200) {
        final homeController = Get.find<HomeController>();
        final current = homeController.user.value;
        if (current != null) {
          homeController.updateUser(
            User(
              id: current.id,
              name: name,
              email: email,
              photoUrl: current.photoUrl,
              hasHealthIssues: current.hasHealthIssues,
              conditions: current.conditions,
              notes: current.notes,
              allergies: current.allergies,
              intolerances: current.intolerances,
              chronicConditions: current.chronicConditions,
              weightManagementGoals: current.weightManagementGoals,
              digestiveIssues: current.digestiveIssues,
              cholesterolConcerns: current.cholesterolConcerns,
              kidneyHealthConcerns: current.kidneyHealthConcerns,
              lifestylePreferences: current.lifestylePreferences,
              dietaryGoals: current.dietaryGoals,
              optionalTags: current.optionalTags,
              preferencesCompleted: current.preferencesCompleted,
              weightKg: current.weightKg,
              heightCm: current.heightCm,
              primaryWeightGoal: current.primaryWeightGoal,
              activityLevel: current.activityLevel,
            ),
          );
        }

        Get.snackbar(
          'Profile updated',
          'Your personal information has been updated.',
          snackPosition: SnackPosition.BOTTOM,
        );
        Get.offNamed(AppRoutes.manageAccount);
      } else {
        Get.snackbar(
          'Update failed',
          'Could not update your profile. Please try again.',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (_) {
      Get.snackbar(
        'Update failed',
        'Could not update your profile. Please check your connection and try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFF6F4FB),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveProfile,
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save changes'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
