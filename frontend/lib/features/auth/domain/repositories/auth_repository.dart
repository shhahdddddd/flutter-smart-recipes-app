import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/auth_session.dart';
import '../entities/health_profile_input.dart';
import '../entities/user.dart';

abstract class AuthRepository {
  Future<Either<Failure, AuthSession>> register({
    required String name,
    required String email,
    required String password,
    HealthProfileInput? healthProfile,
  });

  Future<Either<Failure, AuthSession>> login({
    required String email,
    required String password,
  });

  Future<Either<Failure, User>> completeHealthProfile({
    required String token,
    required HealthProfileInput input,
  });

  AuthSession? getCachedSession();

  Future<void> logout();
}
