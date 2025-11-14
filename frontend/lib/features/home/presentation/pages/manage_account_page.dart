import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/utils/constants.dart';
import '../../../../injection_container.dart' as di;
import '../../../auth/domain/entities/user.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../../../routes/app_routes.dart';
import '../controllers/home_controller.dart';

class ManageAccountPage extends StatelessWidget {
  const ManageAccountPage({super.key});

  Future<void> _confirmAndDeleteAccount(BuildContext context) async {
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

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete account?'),
          content: const Text(
            'This will permanently delete your account, health profile, and AI-generated recipes. This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      final response = await http.delete(
        Uri.parse('${AppConstants.baseUrl}/users/profile'),
        headers: {
          'Authorization': 'Bearer ${session.token}',
        },
      );

      if (response.statusCode == 200) {
        await authRepository.logout();
        Get.offAllNamed(AppRoutes.login);
        Get.snackbar(
          'Account deleted',
          'Your account and data have been removed.',
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        Get.snackbar(
          'Delete failed',
          'Could not delete your account. Please try again.',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (_) {
      Get.snackbar(
        'Delete failed',
        'Could not delete your account. Please check your connection and try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> _pickAndUploadPhoto(BuildContext context, User user) async {
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

    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      imageQuality: 85,
    );

    if (picked == null) return;

    try {
      final uri = Uri.parse('${AppConstants.baseUrl}/users/profile/photo');
      final request = http.MultipartRequest('POST', uri)
        ..headers['Authorization'] = 'Bearer ${session.token}';

      http.MultipartFile file;
      if (kIsWeb) {
        final bytes = await picked.readAsBytes();
        file = http.MultipartFile.fromBytes(
          'photo',
          bytes,
          filename: picked.name,
          contentType: MediaType('image', 'jpeg'),
        );
      } else {
        file = await http.MultipartFile.fromPath('photo', picked.path);
      }

      request.files.add(file);

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode == 200) {
        try {
          final map = jsonDecode(response.body) as Map<String, dynamic>;
          final data = map['data'] as Map<String, dynamic>;
          final newPhotoUrl = (data['photoUrl'] ?? '').toString();

          if (newPhotoUrl.isNotEmpty) {
            final controller = Get.find<HomeController>();
            controller.updateUser(
              User(
                id: user.id,
                name: user.name,
                email: user.email,
                photoUrl: newPhotoUrl,
                hasHealthIssues: user.hasHealthIssues,
                conditions: user.conditions,
                notes: user.notes,
                allergies: user.allergies,
                intolerances: user.intolerances,
                chronicConditions: user.chronicConditions,
                weightManagementGoals: user.weightManagementGoals,
                digestiveIssues: user.digestiveIssues,
                cholesterolConcerns: user.cholesterolConcerns,
                kidneyHealthConcerns: user.kidneyHealthConcerns,
                lifestylePreferences: user.lifestylePreferences,
                dietaryGoals: user.dietaryGoals,
                optionalTags: user.optionalTags,
                preferencesCompleted: user.preferencesCompleted,
                weightKg: user.weightKg,
                heightCm: user.heightCm,
                primaryWeightGoal: user.primaryWeightGoal,
                activityLevel: user.activityLevel,
              ),
            );

            Get.snackbar(
              'Photo updated',
              'Your profile picture has been updated.',
              snackPosition: SnackPosition.BOTTOM,
            );
            return;
          }
        } catch (_) {
          // fall through to generic error message
        }

        Get.snackbar(
          'Update failed',
          'Could not update your profile photo. Please try again.',
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        String message = 'Could not update your profile photo (code ${response.statusCode}).';
        try {
          final decoded = jsonDecode(response.body);
          if (decoded is Map<String, dynamic> && decoded['error'] != null) {
            message = decoded['error'].toString();
          }
        } catch (_) {
          // ignore JSON parse error, keep default message
        }

        Get.snackbar(
          'Update failed',
          message,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Network error',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> _editPersonalInfo(BuildContext context, User user) async {
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

    final nameController = TextEditingController(text: user.name);
    final emailController = TextEditingController(text: user.email);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit profile'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    final name = nameController.text.trim();
    final email = emailController.text.trim();

    if (name.isEmpty || email.isEmpty) {
      Get.snackbar(
        'Invalid data',
        'Name and email cannot be empty.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    try {
      final response = await http.put(
        Uri.parse('${AppConstants.baseUrl}/users/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${session.token}',
        },
        body: '{"name":"$name","email":"$email"}',
      );

      if (response.statusCode == 200) {
        final controller = Get.find<HomeController>();
        controller.updateUser(
          User(
            id: user.id,
            name: name,
            email: email,
            hasHealthIssues: user.hasHealthIssues,
            conditions: user.conditions,
            notes: user.notes,
            allergies: user.allergies,
            intolerances: user.intolerances,
            chronicConditions: user.chronicConditions,
            weightManagementGoals: user.weightManagementGoals,
            digestiveIssues: user.digestiveIssues,
            cholesterolConcerns: user.cholesterolConcerns,
            kidneyHealthConcerns: user.kidneyHealthConcerns,
            lifestylePreferences: user.lifestylePreferences,
            dietaryGoals: user.dietaryGoals,
            optionalTags: user.optionalTags,
            preferencesCompleted: user.preferencesCompleted,
            weightKg: user.weightKg,
            heightCm: user.heightCm,
            primaryWeightGoal: user.primaryWeightGoal,
            activityLevel: user.activityLevel,
          ),
        );

        Get.snackbar(
          'Profile updated',
          'Your personal information has been updated.',
          snackPosition: SnackPosition.BOTTOM,
        );
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
    }
  }

  Future<void> _changePassword(BuildContext context) async {
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

    final passwordController = TextEditingController();
    final confirmController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Change password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: passwordController,
                decoration: const InputDecoration(labelText: 'New password'),
                obscureText: true,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmController,
                decoration: const InputDecoration(labelText: 'Confirm password'),
                obscureText: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    final password = passwordController.text;
    final confirm = confirmController.text;

    if (password.isEmpty || password.length < 6 || password != confirm) {
      Get.snackbar(
        'Invalid password',
        'Passwords must match and be at least 6 characters long.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    try {
      final response = await http.put(
        Uri.parse('${AppConstants.baseUrl}/users/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${session.token}',
        },
        body: '{"password":"$password"}',
      );

      if (response.statusCode == 200) {
        Get.snackbar(
          'Password updated',
          'Your password has been changed.',
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        Get.snackbar(
          'Update failed',
          'Could not change your password. Please try again.',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (_) {
      Get.snackbar(
        'Update failed',
        'Could not change your password. Please check your connection and try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = Get.find<HomeController>();

    return Scaffold(
      backgroundColor: const Color(0xFFF6F4FB),
      appBar: AppBar(
        title: const Text('Manage Account'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: Obx(
        () {
          final user = controller.user.value;
          if (user == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final conditions = _collectConditions(user);
          final conditionsMetric = conditions.length.toString();
          final conditionsDescription = conditions.isEmpty
              ? 'No conditions recorded yet'
              : '${conditions.take(3).join(' • ')}${conditions.length > 3 ? ' +' : ''}';

          final allGoals = [
            ...user.weightManagementGoals,
            ...user.dietaryGoals,
          ].where((goal) => goal.trim().isNotEmpty).toList();
          final primaryGoal = allGoals.isNotEmpty ? allGoals.first : 'Personalized wellness';
          final additionalGoals = allGoals.skip(1).where((goal) => goal != primaryGoal).toList();
          final goalSubtitle = additionalGoals.isEmpty
              ? 'Update your goals to tailor suggestions further'
              : 'Also focusing on ${additionalGoals.take(2).join(', ')}';
          final goalProgress = user.preferencesCompleted ? 1.0 : 0.35;

          final notes = user.notes?.trim();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ProfileHeader(
                  theme: theme,
                  user: user,
                  onChangePhoto: () => _pickAndUploadPhoto(context, user),
                ),
                const SizedBox(height: 24),
                Text(
                  'Health Snapshot',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                _HighlightCard(
                  title: 'Active conditions',
                  metric: conditionsMetric,
                  description: conditionsDescription,
                  color: const Color(0xFF7C4DFF),
                ),
                const SizedBox(height: 16),
                _GoalCard(
                  theme: theme,
                  goal: primaryGoal,
                  target: goalSubtitle,
                  progress: goalProgress,
                ),
                const SizedBox(height: 24),
                _HealthSnapshotGroup(
                  theme: theme,
                  title: 'Allergies',
                  items: user.allergies,
                  accentColor: const Color(0xFFFF7043),
                ),
                const SizedBox(height: 16),
                _HealthSnapshotGroup(
                  theme: theme,
                  title: 'Intolerances',
                  items: user.intolerances,
                  accentColor: const Color(0xFFFFA726),
                ),
                const SizedBox(height: 16),
                _HealthSnapshotGroup(
                  theme: theme,
                  title: 'Dietary Goals',
                  items: user.dietaryGoals.isNotEmpty ? user.dietaryGoals : user.weightManagementGoals,
                  accentColor: const Color(0xFF00BFA6),
                ),
                const SizedBox(height: 16),
                _HealthSnapshotGroup(
                  theme: theme,
                  title: 'Lifestyle Preferences',
                  items: user.lifestylePreferences,
                  accentColor: const Color(0xFF7C4DFF),
                ),
                if (notes != null && notes.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _NotesPreview(theme: theme, note: notes),
                ],
                const SizedBox(height: 32),
                Text(
                  'Account Settings',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                _SettingsCard(
                  icon: Icons.person_outline,
                  title: 'Personal Information',
                  subtitle: 'Update name, email, and contact details',
                  onTap: () => _editPersonalInfo(context, user),
                ),
                const SizedBox(height: 12),
                _SettingsCard(
                  icon: Icons.lock_outline,
                  title: 'Security',
                  subtitle: 'Change password and manage sign-in options',
                  onTap: () => _changePassword(context),
                ),
                const SizedBox(height: 12),
                _SettingsCard(
                  icon: Icons.notifications_outlined,
                  title: 'Notifications',
                  subtitle: 'Choose the updates you want to receive',
                ),
                const SizedBox(height: 32),
                Text(
                  'Connected Services',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                _IntegrationTile(
                  logo: Icons.health_and_safety_outlined,
                  title: 'Health Sync',
                  description: 'Connect Apple Health / Google Fit to sync activity.',
                  enabled: true,
                ),
                _IntegrationTile(
                  logo: Icons.fastfood_outlined,
                  title: 'Nutrition Apps',
                  description: 'Link MyFitnessPal to import calorie targets.',
                ),
                const SizedBox(height: 32),
                Text(
                  'Danger Zone',
                  style: theme.textTheme.titleMedium?.copyWith(color: Colors.red.shade400, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                _DangerButton(
                  label: 'Delete Account',
                  description: 'Permanently remove all data and saved recipes.',
                  onPressed: () => _confirmAndDeleteAccount(context),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<String> _collectConditions(User user) {
    final combined = <String>{
      ...user.conditions.map((c) => c.trim()).where((c) => c.isNotEmpty),
      ...user.chronicConditions.map((c) => c.trim()).where((c) => c.isNotEmpty),
      ...user.digestiveIssues.map((c) => c.trim()).where((c) => c.isNotEmpty),
      ...user.cholesterolConcerns.map((c) => c.trim()).where((c) => c.isNotEmpty),
      ...user.kidneyHealthConcerns.map((c) => c.trim()).where((c) => c.isNotEmpty),
    };

    final sorted = combined.toList()..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return sorted;
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.theme,
    required this.user,
    required this.onChangePhoto,
  });

  final ThemeData theme;
  final User user;
  final VoidCallback onChangePhoto;

  @override
  Widget build(BuildContext context) {
    final spotlightBadges = _buildSpotlightBadges(user);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: const Color(0xFF7C4DFF),
            backgroundImage: user.photoUrl != null && user.photoUrl!.isNotEmpty
                ? NetworkImage(user.photoUrl!)
                : null,
            child: (user.photoUrl == null || user.photoUrl!.isEmpty)
                ? const Icon(Icons.person, size: 40, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  user.email,
                  style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
                ),
                if (spotlightBadges.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: spotlightBadges,
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            onPressed: onChangePhoto,
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Change profile photo',
          ),
        ],
      ),
    );
  }

  List<Widget> _buildSpotlightBadges(User user) {
    final badges = <Widget>[];

    if (user.allergies.isNotEmpty) {
      badges.add(_Badge(label: 'Allergies: ${user.allergies.first}'));
    } else if (user.intolerances.isNotEmpty) {
      badges.add(_Badge(label: 'Intolerance: ${user.intolerances.first}'));
    }

    final primaryGoal = [
      ...user.weightManagementGoals,
      ...user.dietaryGoals,
    ].where((goal) => goal.trim().isNotEmpty).toList();

    if (primaryGoal.isNotEmpty) {
      badges.add(_Badge(label: 'Goal: ${primaryGoal.first}'));
    }

    if (user.lifestylePreferences.isNotEmpty) {
      badges.add(_Badge(label: user.lifestylePreferences.first));
    }

    return badges;
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF7C4DFF).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF7C4DFF),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _HighlightCard extends StatelessWidget {
  const _HighlightCard({
    required this.title,
    required this.metric,
    required this.description,
    required this.color,
  });

  final String title;
  final String metric;
  final String description;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 54,
            width: 54,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(18),
            ),
            alignment: Alignment.center,
            child: Text(
              metric,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({
    required this.theme,
    required this.goal,
    required this.target,
    required this.progress,
  });

  final ThemeData theme;
  final String goal;
  final String target;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 18,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 42,
                width: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFF00BFA6).withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.flag_outlined, color: Color(0xFF00BFA6)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      goal,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      target,
                      style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              Text(
                '${(progress * 100).round()}%',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF00BFA6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 10,
              backgroundColor: Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation(Color(0xFF00BFA6)),
            ),
          ),
        ],
      ),
    );
  }
}

class _HealthSnapshotGroup extends StatelessWidget {
  const _HealthSnapshotGroup({
    required this.theme,
    required this.title,
    required this.items,
    required this.accentColor,
  });

  final ThemeData theme;
  final String title;
  final List<String> items;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final cleanedItems = items.map((item) => item.trim()).where((item) => item.isNotEmpty).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 18,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.local_florist_outlined, color: accentColor),
              ),
              const SizedBox(width: 14),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (cleanedItems.isEmpty)
            Text(
              'Nothing recorded yet',
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade500),
            )
          else
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: cleanedItems
                  .map(
                    (item) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        item,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: accentColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }
}

class _NotesPreview extends StatelessWidget {
  const _NotesPreview({required this.theme, required this.note});

  final ThemeData theme;
  final String note;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 18,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 38,
                width: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFF7C4DFF).withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.notes_outlined, color: Color(0xFF7C4DFF)),
              ),
              const SizedBox(width: 12),
              Text(
                'Notes',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            note,
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF7C4DFF).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: const Color(0xFF7C4DFF)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 18, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}

class _IntegrationTile extends StatelessWidget {
  const _IntegrationTile({
    required this.logo,
    required this.title,
    required this.description,
    this.enabled = false,
  });

  final IconData logo;
  final String title;
  final String description;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 46,
            width: 46,
            decoration: BoxDecoration(
              color: const Color(0xFF00BFA6).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(logo, color: const Color(0xFF00BFA6)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    if (enabled)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00BFA6).withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Connected',
                          style: TextStyle(
                            color: Color(0xFF00BFA6),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch(
            value: enabled,
            onChanged: (_) {},
            activeColor: const Color(0xFF00BFA6),
          ),
        ],
      ),
    );
  }
}

class _DangerButton extends StatelessWidget {
  const _DangerButton({
    required this.label,
    required this.description,
    required this.onPressed,
  });

  final String label;
  final String description;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 46,
            width: 46,
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.warning_amber_outlined, color: Colors.red.shade400),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Colors.red.shade400,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          TextButton(
            onPressed: onPressed,
            style: TextButton.styleFrom(foregroundColor: Colors.red.shade400),
            child: const Text('Manage'),
          ),
        ],
      ),
    );
  }
}
