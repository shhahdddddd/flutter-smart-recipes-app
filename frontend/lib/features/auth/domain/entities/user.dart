class User {
  final String id;
  final String name;
  final String email;
  final String? photoUrl;
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

  const User({
    required this.id,
    required this.name,
    required this.email,
    this.photoUrl,
    required this.hasHealthIssues,
    required this.conditions,
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
}
