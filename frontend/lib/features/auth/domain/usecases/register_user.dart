import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/auth_session.dart';
import '../entities/health_profile_input.dart';
import '../repositories/auth_repository.dart';

class RegisterUser {
  final AuthRepository repository;

  RegisterUser(this.repository);

  Future<Either<Failure, AuthSession>> call({
    required String name,
    required String email,
    required String password,
    HealthProfileInput? healthProfile,
  }) {
    return repository.register(
      name: name,
      email: email,
      password: password,
      healthProfile: healthProfile,
    );
  }
}
