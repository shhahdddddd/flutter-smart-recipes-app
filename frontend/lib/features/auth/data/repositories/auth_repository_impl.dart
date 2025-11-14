import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/entities/health_profile_input.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/local/auth_local_data_source.dart';
import '../datasources/remote/auth_remote_data_source.dart';
import '../models/auth_session_model.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<Either<Failure, AuthSession>> register({
    required String name,
    required String email,
    required String password,
    HealthProfileInput? healthProfile,
  }) async {
    try {
      final session = await remoteDataSource.register(
        name: name,
        email: email,
        password: password,
        healthProfile: healthProfile,
      );
      await localDataSource.cacheSession(session);
      return Right(session);
    } on ServerException catch (error) {
      return Left(ServerFailure(message: error.message, statusCode: error.statusCode));
    } catch (_) {
      return const Left(ServerFailure(message: 'Une erreur inattendue est survenue'));
    }
  }

  @override
  Future<Either<Failure, AuthSession>> login({
    required String email,
    required String password,
  }) async {
    try {
      final session = await remoteDataSource.login(
        email: email,
        password: password,
      );
      await localDataSource.cacheSession(session);
      return Right(session);
    } on ServerException catch (error) {
      return Left(ServerFailure(message: error.message, statusCode: error.statusCode));
    } catch (_) {
      return const Left(ServerFailure(message: 'Une erreur inattendue est survenue'));
    }
  }

  @override
  AuthSession? getCachedSession() => localDataSource.getCachedSession();

  @override
  Future<void> logout() async {
    await localDataSource.clearSession();
  }

  @override
  Future<Either<Failure, User>> completeHealthProfile({
    required String token,
    required HealthProfileInput input,
  }) async {
    try {
      final updatedUser = await remoteDataSource.completeHealthProfile(
        token: token,
        input: input,
      );

      final currentSession = localDataSource.getCachedSession();
      if (currentSession != null) {
        final refreshedSession = AuthSessionModel(
          user: UserModel(
            id: updatedUser.id,
            name: updatedUser.name,
            email: updatedUser.email,
            hasHealthIssues: updatedUser.hasHealthIssues,
            conditions: updatedUser.conditions,
            notes: updatedUser.notes,
            allergies: updatedUser.allergies,
            intolerances: updatedUser.intolerances,
            chronicConditions: updatedUser.chronicConditions,
            weightManagementGoals: updatedUser.weightManagementGoals,
            digestiveIssues: updatedUser.digestiveIssues,
            cholesterolConcerns: updatedUser.cholesterolConcerns,
            kidneyHealthConcerns: updatedUser.kidneyHealthConcerns,
            lifestylePreferences: updatedUser.lifestylePreferences,
            dietaryGoals: updatedUser.dietaryGoals,
            optionalTags: updatedUser.optionalTags,
            preferencesCompleted: updatedUser.preferencesCompleted,
          ),
          token: currentSession.token,
        );
        await localDataSource.cacheSession(refreshedSession);
      }

      return Right(updatedUser);
    } on ServerException catch (error) {
      return Left(ServerFailure(message: error.message, statusCode: error.statusCode));
    } catch (_) {
      return const Left(ServerFailure(message: 'Une erreur inattendue est survenue'));
    }
  }
}
