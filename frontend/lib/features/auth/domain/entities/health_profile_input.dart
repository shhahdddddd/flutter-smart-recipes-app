class HealthProfileInput {
  final bool hasHealthIssues;
  final List<String> conditions;
  final String? notes;
  final List<String> allergies;
  final List<String> intolerances;
  final List<String> chronicConditions;
  final List<String> weightManagementGoals;
  final List<String> digestiveIssues;
  final List<String> cholesterolConcerns;
  final List<String> kidneyHealthConcerns;
  final List<String> lifestylePreferences;
  final List<String> dietaryGoals;
  final List<String> optionalTags;
  final bool preferencesCompleted;
  final double? weightKg;
  final double? heightCm;
  final String? primaryWeightGoal;
  final String? activityLevel;

  const HealthProfileInput({
    required this.hasHealthIssues,
    this.conditions = const [],
    this.notes,
    this.allergies = const [],
    this.intolerances = const [],
    this.chronicConditions = const [],
    this.weightManagementGoals = const [],
    this.digestiveIssues = const [],
    this.cholesterolConcerns = const [],
    this.kidneyHealthConcerns = const [],
    this.lifestylePreferences = const [],
    this.dietaryGoals = const [],
    this.optionalTags = const [],
    this.preferencesCompleted = false,
    this.weightKg,
    this.heightCm,
    this.primaryWeightGoal,
    this.activityLevel,
  });

  Map<String, dynamic> toJson() {
    return {
      'hasHealthIssues': hasHealthIssues,
      'conditions': conditions,
      if (notes != null && notes!.trim().isNotEmpty) 'notes': notes!.trim(),
      'allergies': allergies,
      'intolerances': intolerances,
      'chronicConditions': chronicConditions,
      'weightManagementGoals': weightManagementGoals,
      'digestiveIssues': digestiveIssues,
      'cholesterolConcerns': cholesterolConcerns,
      'kidneyHealthConcerns': kidneyHealthConcerns,
      'lifestylePreferences': lifestylePreferences,
      'dietaryGoals': dietaryGoals,
      'optionalTags': optionalTags,
      'preferencesCompleted': preferencesCompleted,
      if (weightKg != null) 'weightKg': weightKg,
      if (heightCm != null) 'heightCm': heightCm,
      if (primaryWeightGoal != null) 'primaryWeightGoal': primaryWeightGoal,
      if (activityLevel != null) 'activityLevel': activityLevel,
    };
  }
}
