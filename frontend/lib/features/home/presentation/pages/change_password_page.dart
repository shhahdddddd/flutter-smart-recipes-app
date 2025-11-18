import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../../../../core/utils/constants.dart';
import '../../../../injection_container.dart' as di;
import '../../../auth/domain/repositories/auth_repository.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _savePassword() async {
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

    final password = _passwordController.text;
    final confirm = _confirmController.text;

    if (password.isEmpty || password.length < 6 || password != confirm) {
      Get.snackbar(
        'Invalid password',
        'Passwords must match and be at least 6 characters long.',
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
        body: jsonEncode({'password': password}),
      );

      if (response.statusCode == 200) {
        Get.snackbar(
          'Password updated',
          'Your password has been changed.',
          snackPosition: SnackPosition.BOTTOM,
        );
        Get.back();
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
        title: const Text('Security'),
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
            Text(
              'Change password',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Choose a strong password to keep your account secure.',
              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'New password'),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _confirmController,
              decoration: const InputDecoration(labelText: 'Confirm password'),
              obscureText: true,
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _savePassword,
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save password'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
