import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../auth/domain/entities/health_profile_input.dart';
import '../../../auth/domain/entities/user.dart';
import '../controllers/home_controller.dart';

class HealthPreferencesPage extends StatefulWidget {
  const HealthPreferencesPage({super.key});

  @override
  State<HealthPreferencesPage> createState() => _HealthPreferencesPageState();
}

class _HealthPreferencesPageState extends State<HealthPreferencesPage> {
  static const _weightGoalOptions = ['Lose weight', 'Maintain weight', 'Gain weight'];
  static const _activityLevels = [
    'Mostly sedentary',
    'Lightly active',
    'Moderately busy',
    'Very busy',
    'Athlete / highly active',
  ];

  final _formKey = GlobalKey<FormState>();
  late final HomeController _controller;

  bool _hasHealthIssues = false;
  List<String> _conditions = [];
  List<String> _allergies = [];
  List<String> _intolerances = [];
  List<String> _chronicConditions = [];
  List<String> _digestiveIssues = [];
  List<String> _cholesterolConcerns = [];
  List<String> _kidneyHealthConcerns = [];
  List<String> _weightManagementGoals = [];
  List<String> _lifestylePreferences = [];
  List<String> _dietaryGoals = [];
  List<String> _optionalTags = [];

  String? _primaryWeightGoal;
  String? _activityLevel;
  String? _kidneyStatus; // Normal / Good / Bad
  String? _lifestylePreference; // Halal / Vegan / Gluten-free / etc.

  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();

  String? _userSignature;

  @override
  void initState() {
    super.initState();
    _controller = Get.find<HomeController>();
  }

  Widget _buildKidneyHealthSection(ThemeData theme) {
    const options = ['Normal', 'Good', 'Bad'];

    return _SectionCard(
      title: 'Kidney health',
      description: 'Overall status so we can adjust sodium, potassium, and protein if needed.',
      child: Wrap(
        spacing: 8,
        children: options.map((status) {
          final selected = _kidneyStatus == status;
          return ChoiceChip(
            label: Text(status),
            selected: selected,
            onSelected: (value) {
              setState(() {
                _kidneyStatus = value ? status : null;
              });
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLifestylePreferenceSection(ThemeData theme) {
    const options = [
      'None',
      'Halal',
      'Vegan',
      'Vegetarian',
      'Gluten-free',
      'Dairy-free',
    ];

    return _SectionCard(
      title: 'Lifestyle preferences',
      description: 'High-level dietary pattern for your meals.',
      child: DropdownButtonFormField<String>(
        value: _lifestylePreference ?? 'None',
        items: options
            .map(
              (value) => DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              ),
            )
            .toList(),
        decoration: const InputDecoration(
          labelText: 'Lifestyle preference',
        ),
        onChanged: (value) {
          setState(() {
            _lifestylePreference = value == 'None' ? null : value;
          });
        },
      ),
    );
  }

  Widget _buildHealthConditionsSection(ThemeData theme) {
    return _SectionCard(
      title: 'Health conditions',
      description: 'Diagnoses or ongoing conditions to keep in mind.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            children: [
              ChoiceChip(
                label: const Text('No'),
                selected: !_hasHealthIssues,
                onSelected: (selected) {
                  setState(() {
                    _hasHealthIssues = false;
                    _conditions.clear();
                  });
                },
              ),
              ChoiceChip(
                label: const Text('Yes'),
                selected: _hasHealthIssues,
                onSelected: (selected) {
                  setState(() {
                    _hasHealthIssues = true;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_hasHealthIssues)
            _buildTagSection(
              theme: theme,
              title: 'Conditions list',
              description: 'Add the diagnoses or ongoing conditions you want us to consider.',
              values: _conditions,
              accent: const Color(0xFF7C4DFF),
              onAdd: () => _promptAdd('Add condition', _conditions),
              onDelete: (value) => _removeTag(_conditions, value),
            )
          else
            Text(
              'No health conditions reported.',
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _notesController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F4FB),
      appBar: AppBar(
        title: const Text('My Health & Preferences'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: Obx(() {
        final user = _controller.user.value;
        final isSaving = _controller.isSaving.value;

        if (user == null) {
          return const Center(child: CircularProgressIndicator());
        }

        final signature = _signatureFor(user);
        if (_userSignature != signature) {
          _hydrateFromUser(user);
          _userSignature = signature;
        }

        final theme = Theme.of(context);

        return Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SummarySection(
                      conditions: _conditions,
                      weightText: _weightController.text,
                      heightText: _heightController.text,
                      primaryGoal: _primaryWeightGoal,
                      activityLevel: _activityLevel,
                    ),
                    const SizedBox(height: 24),
                    _buildMetricsSection(theme),
                    const SizedBox(height: 24),
                    _buildHealthConditionsSection(theme),
                    const SizedBox(height: 24),
                    _buildTagSection(
                      theme: theme,
                      title: 'Allergies',
                      description: 'Ingredients you need to avoid entirely.',
                      values: _allergies,
                      accent: const Color(0xFFFF7043),
                      onAdd: () => _promptAdd('Add allergy', _allergies),
                      onDelete: (value) => _removeTag(_allergies, value),
                    ),
                    const SizedBox(height: 24),
                    _buildTagSection(
                      theme: theme,
                      title: 'Intolerances',
                      description: 'Foods that cause discomfort or sensitivity.',
                      values: _intolerances,
                      accent: const Color(0xFFFFB74D),
                      onAdd: () => _promptAdd('Add intolerance', _intolerances),
                      onDelete: (value) => _removeTag(_intolerances, value),
                    ),
                    const SizedBox(height: 24),
                    _buildKidneyHealthSection(theme),
                    const SizedBox(height: 24),
                    _buildLifestylePreferenceSection(theme),
                    const SizedBox(height: 24),
                    // Dietary goals, additional weight goals, optional tags and nutrition notes removed from UI
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: const Color(0xFF7C4DFF),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: isSaving ? null : _save,
                        icon: isSaving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.4),
                              )
                            : const Icon(Icons.save_outlined),
                        label: Text(
                          isSaving ? 'Saving...' : 'Save preferences',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (isSaving)
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    color: Colors.black.withOpacity(0.05),
                  ),
                ),
              ),
          ],
        );
      }),
    );
  }

  void _hydrateFromUser(User user) {
    _hasHealthIssues = user.hasHealthIssues;
    _conditions = List<String>.from(user.conditions);
    _allergies = List<String>.from(user.allergies);
    _intolerances = List<String>.from(user.intolerances);
    _chronicConditions = List<String>.from(user.chronicConditions);
    _digestiveIssues = List<String>.from(user.digestiveIssues);
    _cholesterolConcerns = List<String>.from(user.cholesterolConcerns);
    _kidneyHealthConcerns = List<String>.from(user.kidneyHealthConcerns);
    _weightManagementGoals = List<String>.from(user.weightManagementGoals);
    _lifestylePreferences = List<String>.from(user.lifestylePreferences);
    _dietaryGoals = List<String>.from(user.dietaryGoals);
    _optionalTags = List<String>.from(user.optionalTags);

    _notesController.text = user.notes ?? '';
    _weightController.text = user.weightKg?.toString() ?? '';
    _heightController.text = user.heightCm?.toString() ?? '';

    _primaryWeightGoal = user.primaryWeightGoal ?? (_weightManagementGoals.isNotEmpty ? _weightManagementGoals.first : null);
    _activityLevel = user.activityLevel;
    _kidneyStatus = _kidneyHealthConcerns.isNotEmpty ? _kidneyHealthConcerns.first : null;
    _lifestylePreference = _lifestylePreferences.isNotEmpty ? _lifestylePreferences.first : null;
  }

  String _signatureFor(User user) {
    return [
      user.id,
      user.hasHealthIssues.toString(),
      user.conditions.join('|'),
      user.allergies.join('|'),
      user.intolerances.join('|'),
      user.chronicConditions.join('|'),
      user.digestiveIssues.join('|'),
      user.cholesterolConcerns.join('|'),
      user.kidneyHealthConcerns.join('|'),
      user.weightManagementGoals.join('|'),
      user.lifestylePreferences.join('|'),
      user.dietaryGoals.join('|'),
      user.optionalTags.join('|'),
      user.notes ?? '',
      user.weightKg?.toString() ?? '',
      user.heightCm?.toString() ?? '',
      user.primaryWeightGoal ?? '',
      user.activityLevel ?? '',
    ].join('~');
  }

  Widget _buildMetricsSection(ThemeData theme) {
    return _SectionCard(
      title: 'Body metrics & lifestyle',
      description: 'Keep these up to date so meal plans match your routine.',
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _weightController,
                  decoration: const InputDecoration(
                    labelText: 'Weight (kg)',
                    hintText: 'e.g. 72.5',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                  validator: _numberValidator,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _heightController,
                  decoration: const InputDecoration(
                    labelText: 'Height (cm)',
                    hintText: 'e.g. 176',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                  validator: _numberValidator,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _primaryWeightGoal,
            items: _weightGoalOptions
                .map((goal) => DropdownMenuItem<String>(
                      value: goal,
                      child: Text(goal),
                    ))
                .toList(),
            decoration: const InputDecoration(labelText: 'Primary weight goal'),
            hint: const Text('Select main goal'),
            onChanged: (value) {
              setState(() {
                _primaryWeightGoal = value;
              });
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _activityLevel,
            items: _activityLevels
                .map((level) => DropdownMenuItem<String>(
                      value: level,
                      child: Text(level),
                    ))
                .toList(),
            decoration: const InputDecoration(labelText: 'Daily routine / activity level'),
            hint: const Text('How busy is your lifestyle?'),
            onChanged: (value) {
              setState(() {
                _activityLevel = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNotesSection(ThemeData theme) {
    return _SectionCard(
      title: 'Notes for your nutritionist',
      description: 'Share context like preferred meal times or flavour notes.',
      child: TextFormField(
        controller: _notesController,
        minLines: 3,
        maxLines: 5,
        decoration: const InputDecoration(
          hintText: 'E.g. lighter dinners on weekdays, avoid spicy food…',
        ),
      ),
    );
  }

  Widget _buildTagSection({
    required ThemeData theme,
    required String title,
    required String description,
    required List<String> values,
    required Color accent,
    required VoidCallback onAdd,
    required ValueChanged<String> onDelete,
    bool enabled = true,
  }) {
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: _SectionCard(
        title: title,
        description: description,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (values.isEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  'No entries yet. Tap “Add” to include one.',
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                ),
              ),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                ...values.map(
                  (value) => InputChip(
                    label: Text(value),
                    backgroundColor: accent.withOpacity(0.12),
                    labelStyle: TextStyle(
                      color: accent,
                      fontWeight: FontWeight.w600,
                    ),
                    onDeleted: enabled ? () => onDelete(value) : null,
                    deleteIcon: enabled ? const Icon(Icons.close, size: 18) : null,
                  ),
                ),
                ActionChip(
                  label: const Text('Add'),
                  avatar: Icon(Icons.add, size: 18, color: accent),
                  onPressed: enabled ? onAdd : null,
                  labelStyle: TextStyle(color: accent, fontWeight: FontWeight.w600),
                  backgroundColor: accent.withOpacity(0.08),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String? _numberValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    final parsed = double.tryParse(value);
    if (parsed == null || parsed <= 0) {
      return 'Enter a valid number';
    }
    return null;
  }

  Future<void> _promptAdd(String title, List<String> target) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'Type and press add'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(controller.text.trim()),
              child: const Text('Add'),
            ),
          ],
        );
      },
    );

    if (result != null) {
      _addTag(target, result);
    }
  }

  void _addTag(List<String> target, String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return;
    final lower = trimmed.toLowerCase();
    setState(() {
      if (target.any((existing) => existing.toLowerCase() == lower)) return;
      target.add(trimmed);
    });
  }

  void _removeTag(List<String> target, String value) {
    setState(() {
      target.removeWhere((element) => element.toLowerCase() == value.toLowerCase());
    });
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final weight = double.tryParse(_weightController.text.trim());
    final height = double.tryParse(_heightController.text.trim());

    final weightGoals = List<String>.from(_weightManagementGoals);
    if (_primaryWeightGoal != null && _primaryWeightGoal!.trim().isNotEmpty) {
      final normalized = _primaryWeightGoal!.trim();
      if (!weightGoals.any((goal) => goal.toLowerCase() == normalized.toLowerCase())) {
        weightGoals.insert(0, normalized);
      }
    }

    final kidneyConcerns = <String>[];
    if (_kidneyStatus != null && _kidneyStatus!.trim().isNotEmpty) {
      kidneyConcerns.add(_kidneyStatus!.trim());
    }

    final lifestylePrefs = <String>[];
    if (_lifestylePreference != null && _lifestylePreference!.trim().isNotEmpty) {
      lifestylePrefs.add(_lifestylePreference!.trim());
    }

    final input = HealthProfileInput(
      hasHealthIssues: _hasHealthIssues,
      conditions: _hasHealthIssues ? _conditions : <String>[],
      notes: null,
      allergies: _allergies,
      intolerances: _intolerances,
      chronicConditions: const [],
      weightManagementGoals: weightGoals,
      digestiveIssues: const [],
      cholesterolConcerns: const [],
      kidneyHealthConcerns: kidneyConcerns,
      lifestylePreferences: lifestylePrefs,
      dietaryGoals: const [],
      optionalTags: const [],
      preferencesCompleted: true,
      weightKg: weight,
      heightCm: height,
      primaryWeightGoal: _primaryWeightGoal?.trim().isEmpty ?? true ? null : _primaryWeightGoal!.trim(),
      activityLevel: _activityLevel?.trim().isEmpty ?? true ? null : _activityLevel!.trim(),
    );

    final failure = await _controller.saveHealthProfile(input);
    if (failure != null) {
      Get.snackbar(
        'Save failed',
        failure,
        snackPosition: SnackPosition.BOTTOM,
      );
    } else {
      Get.snackbar(
        'Preferences saved',
        'Your health information has been updated.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.description,
    required this.child,
  });

  final String title;
  final String description;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 16,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                description,
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 16),
              child,
            ],
          ),
        ),
      ],
    );
  }
}

class _SummarySection extends StatelessWidget {
  const _SummarySection({
    required this.conditions,
    required this.weightText,
    required this.heightText,
    required this.primaryGoal,
    required this.activityLevel,
  });

  final List<String> conditions;
  final String weightText;
  final String heightText;
  final String? primaryGoal;
  final String? activityLevel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final conditionCount = conditions.length;
    final conditionDescription = conditionCount == 0
        ? 'Add any diagnoses so we can tailor meals.'
        : '${conditions.take(3).join(' • ')}${conditionCount > 3 ? ' +' : ''}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StatCard(
          icon: Icons.monitor_heart_outlined,
          title: 'Active conditions',
          subtitle: conditionDescription,
          metric: conditionCount.toString(),
          color: const Color(0xFF7C4DFF),
        ),
        const SizedBox(height: 16),
        _BodyOverviewCard(
          weightText: weightText.isEmpty ? 'Not set' : '$weightText kg',
          heightText: heightText.isEmpty ? 'Not set' : '$heightText cm',
          goalText: primaryGoal ?? 'Choose goal',
          activityText: activityLevel ?? 'Not provided',
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.metric,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String metric;
  final Color color;

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
            color: Colors.black.withOpacity(0.06),
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
              color: color.withOpacity(0.14),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: color),
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
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              metric,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BodyOverviewCard extends StatelessWidget {
  const _BodyOverviewCard({
    required this.weightText,
    required this.heightText,
    required this.goalText,
    required this.activityText,
  });

  final String weightText;
  final String heightText;
  final String goalText;
  final String activityText;

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
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Wrap(
        spacing: 16,
        runSpacing: 12,
        children: [
          _MiniMetric(icon: Icons.monitor_weight_outlined, label: 'Weight', value: weightText),
          _MiniMetric(icon: Icons.height, label: 'Height', value: heightText),
          _MiniMetric(icon: Icons.flag_outlined, label: 'Goal', value: goalText),
          _MiniMetric(icon: Icons.run_circle_outlined, label: 'Lifestyle', value: activityText),
        ],
      ),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0ECFF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: const Color(0xFF7C4DFF)),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(color: Colors.grey.shade600),
              ),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
