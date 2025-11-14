import '../../domain/entities/user.dart';

List<String> _listFrom(dynamic source) {
  if (source == null) return const [];
  if (source is List) {
    return source.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
  }
  return [source.toString()].where((e) => e.isNotEmpty).toList();
}

double? _doubleFrom(dynamic source) {
  if (source == null) return null;
  if (source is num) return source.toDouble();
  final parsed = double.tryParse(source.toString());
  return parsed;
}

class UserModel extends User {
  const UserModel({
    required super.id,
    required super.name,
    required super.email,
    super.photoUrl,
    required super.hasHealthIssues,
    required super.conditions,
    super.notes,
    super.allergies,
    super.intolerances,
    super.chronicConditions,
    super.weightManagementGoals,
    super.digestiveIssues,
    super.cholesterolConcerns,
    super.kidneyHealthConcerns,
    super.lifestylePreferences,
    super.dietaryGoals,
    super.optionalTags,
    super.preferencesCompleted,
    super.weightKg,
    super.heightCm,
    super.primaryWeightGoal,
    super.activityLevel,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json;
    final profile = data['healthProfile'] as Map<String, dynamic>?;

    return UserModel(
      id: (data['_id'] ?? data['id']).toString(),
      name: data['name'] as String,
      email: data['email'] as String,
      photoUrl: data['photoUrl'] as String?,
      hasHealthIssues: (profile?['hasHealthIssues'] as bool?) ?? false,
      conditions: _listFrom(profile?['conditions']),
      notes: profile?['notes'] as String?,
      allergies: _listFrom(profile?['allergies']),
      intolerances: _listFrom(profile?['intolerances']),
      chronicConditions: _listFrom(profile?['chronicConditions']),
      weightManagementGoals: _listFrom(profile?['weightManagementGoals']),
      digestiveIssues: _listFrom(profile?['digestiveIssues']),
      cholesterolConcerns: _listFrom(profile?['cholesterolConcerns']),
      kidneyHealthConcerns: _listFrom(profile?['kidneyHealthConcerns']),
      lifestylePreferences: _listFrom(profile?['lifestylePreferences']),
      dietaryGoals: _listFrom(profile?['dietaryGoals']),
      optionalTags: _listFrom(profile?['optionalTags']),
      preferencesCompleted: (profile?['preferencesCompleted'] as bool?) ?? false,
      weightKg: _doubleFrom(profile?['weightKg']),
      heightCm: _doubleFrom(profile?['heightCm']),
      primaryWeightGoal: profile?['primaryWeightGoal'] as String?,
      activityLevel: profile?['activityLevel'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'email': email,
      if (photoUrl != null) 'photoUrl': photoUrl,
      'healthProfile': {
        'hasHealthIssues': hasHealthIssues,
        'conditions': conditions,
        if (notes != null) 'notes': notes,
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
      },
    };
  }
}
