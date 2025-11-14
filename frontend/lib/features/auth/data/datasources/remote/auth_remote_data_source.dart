import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../../core/error/exceptions.dart';
import '../../../../../core/utils/constants.dart';
import '../../../domain/entities/health_profile_input.dart';
import '../../models/auth_session_model.dart';
import '../../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<AuthSessionModel> register({
    required String name,
    required String email,
    required String password,
    HealthProfileInput? healthProfile,
  });

  Future<AuthSessionModel> login({
    required String email,
    required String password,
  });

  Future<UserModel> completeHealthProfile({
    required String token,
    required HealthProfileInput input,
  });
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final http.Client client;

  AuthRemoteDataSourceImpl({required this.client});

  @override
  Future<AuthSessionModel> register({
    required String name,
    required String email,
    required String password,
    HealthProfileInput? healthProfile,
  }) async {
    final profilePayload = healthProfile?.toJson() ??
        const HealthProfileInput(hasHealthIssues: false).toJson();

    final response = await client.post(
      Uri.parse('${AppConstants.baseUrl}/users/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
        'healthProfile': profilePayload,
      }),
    );

    if (response.statusCode == 201) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      return AuthSessionModel.fromJson(decoded['data']);
    }

    throw ServerException(
      message: _parseErrorMessage(response.body),
      statusCode: response.statusCode,
    );
  }

  @override
  Future<UserModel> completeHealthProfile({
    required String token,
    required HealthProfileInput input,
  }) async {
    final response = await client.put(
      Uri.parse('${AppConstants.baseUrl}/users/profile'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'healthProfile': input.toJson(),
      }),
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      return UserModel.fromJson(decoded['data'] as Map<String, dynamic>);
    }

    throw ServerException(
      message: _parseErrorMessage(response.body),
      statusCode: response.statusCode,
    );
  }

  @override
  Future<AuthSessionModel> login({
    required String email,
    required String password,
  }) async {
    final response = await client.post(
      Uri.parse('${AppConstants.baseUrl}/users/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      return AuthSessionModel.fromJson(decoded['data']);
    }

    throw ServerException(
      message: _parseErrorMessage(response.body),
      statusCode: response.statusCode,
    );
  }

  String _parseErrorMessage(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        return decoded['error']?.toString() ?? 'Une erreur est survenue';
      }
      return 'Une erreur est survenue';
    } catch (_) {
      return 'Une erreur est survenue';
    }
  }
}
