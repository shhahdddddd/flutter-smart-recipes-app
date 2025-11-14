import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/health_profile_input.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class CompleteHealthProfile {
  final AuthRepository repository;

  CompleteHealthProfile(this.repository);

  Future<Either<Failure, User>> call({
    required String token,
    required HealthProfileInput input,
  }) {
    return repository.completeHealthProfile(
      token: token,
      input: input,
    );
  }
}
