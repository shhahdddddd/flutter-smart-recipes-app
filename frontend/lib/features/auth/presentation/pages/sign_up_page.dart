import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../routes/app_routes.dart';
import '../controllers/auth_controller.dart';
import '../widgets/gradient_button.dart';

class SignUpPage extends StatelessWidget {
  SignUpPage({super.key});

  final AuthController controller = Get.find<AuthController>();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => Get.back(),
                child: const Icon(Icons.arrow_back_ios_new, size: 20),
              ),
              const SizedBox(height: 16),
              const _IllustrationHeader(),
              const SizedBox(height: 24),
              Text(
                'trusty.',
                style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                'Sign Up',
                style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              Form(
                key: controller.registerFormKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: controller.nameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Your name',
                        hintText: 'e.g. Lucy',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Veuillez saisir votre nom';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: controller.emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email Address',
                        hintText: 'example@mail.com',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Veuillez saisir votre email';
                        }
                        if (!GetUtils.isEmail(value.trim())) {
                          return 'Email invalide';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Obx(
                      () => TextFormField(
                        controller: controller.passwordController,
                        obscureText: controller.obscurePassword.value,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          hintText: 'example_1',
                          suffixIcon: IconButton(
                            icon: Icon(
                              controller.obscurePassword.value
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: controller.togglePasswordVisibility,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Veuillez saisir un mot de passe';
                          }
                          if (value.length < 6) {
                            return 'Au moins 6 caractères requis';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    Obx(
                      () => SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Do you have health issues?'),
                        value: controller.hasHealthIssues.value,
                        onChanged: controller.setHasHealthIssues,
                      ),
                    ),
                    Obx(
                      () => AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: controller.hasHealthIssues.value
                            ? Column(
                                key: const ValueKey(true),
                                children: [
                                  TextFormField(
                                    controller: controller.conditionsController,
                                    decoration: const InputDecoration(
                                      labelText: 'Health conditions',
                                      hintText: 'Separate with commas',
                                    ),
                                    validator: (value) {
                                      if (!controller.hasHealthIssues.value) {
                                        return null;
                                      }
                                      if (value == null || value.trim().isEmpty) {
                                        return 'Veuillez lister vos conditions';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: controller.notesController,
                                    minLines: 2,
                                    maxLines: 4,
                                    decoration: const InputDecoration(
                                      labelText: 'Additional notes',
                                      hintText: 'Informations complémentaires (optionnel)',
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                ],
                              )
                            : const SizedBox.shrink(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Obx(
                      () => GradientButton(
                        label: controller.isLoading.value ? 'Creating...' : 'Create account',
                        onPressed: controller.isLoading.value ? null : controller.register,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: Column(
                  children: [
                    const Text('Or sign up with'),
                    const SizedBox(height: 16),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 16,
                      runSpacing: 12,
                      children: const [
                        _SocialButton(icon: Icons.g_mobiledata, label: 'Google'),
                        _SocialButton(icon: Icons.facebook, label: 'Facebook'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () => Get.toNamed(AppRoutes.login),
                      child: const Text(
                        'Already have an account? Log In',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.black87),
            const SizedBox(width: 8),
            Text(label),
          ],
        ),
      ),
    );
  }
}

class _IllustrationHeader extends StatelessWidget {
  const _IllustrationHeader();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 260;

        Widget illustration = Container(
          height: 96,
          width: isCompact ? double.infinity : 96,
          decoration: BoxDecoration(
            color: const Color(0xFFF2ECFF),
            borderRadius: BorderRadius.circular(24),
          ),
          child: const Center(
            child: Icon(
              Icons.emoji_emotions,
              size: 48,
              color: Color(0xFF7C4DFF),
            ),
          ),
        );

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: isCompact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _IllustrationText(),
                    const SizedBox(height: 16),
                    illustration,
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Expanded(child: _IllustrationText()),
                    const SizedBox(width: 16),
                    SizedBox(width: 96, child: illustration),
                  ],
                ),
        );
      },
    );
  }
}

class _IllustrationText extends StatelessWidget {
  const _IllustrationText();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          'hello',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        SizedBox(height: 12),
        Text(
          "Let’s cook\nsomething great",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            height: 1.2,
          ),
        ),
      ],
    );
  }
}
