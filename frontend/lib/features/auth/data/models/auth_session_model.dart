import '../../domain/entities/auth_session.dart';
import 'user_model.dart';

class AuthSessionModel extends AuthSession {
  AuthSessionModel({required UserModel user, required String token})
      : super(user: user, token: token);

  factory AuthSessionModel.fromJson(Map<String, dynamic> json) {
    final user = UserModel.fromJson(json);
    final token = json['token'] as String? ?? '';

    return AuthSessionModel(
      user: user,
      token: token,
    );
  }

  Map<String, dynamic> toJson() {
    final userModel = user is UserModel
        ? user as UserModel
        : UserModel(
            id: user.id,
            name: user.name,
            email: user.email,
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
          );

    return {
      'token': token,
      ...userModel.toJson(),
    };
  }
}
