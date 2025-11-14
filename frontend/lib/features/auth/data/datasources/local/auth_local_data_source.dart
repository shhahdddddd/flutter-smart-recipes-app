import 'package:get_storage/get_storage.dart';

import '../../models/auth_session_model.dart';

abstract class AuthLocalDataSource {
  Future<void> cacheSession(AuthSessionModel session);
  AuthSessionModel? getCachedSession();
  Future<void> clearSession();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  static const _storageKey = 'auth_session';
  final GetStorage storage;

  AuthLocalDataSourceImpl(this.storage);

  @override
  Future<void> cacheSession(AuthSessionModel session) async {
    await storage.write(_storageKey, session.toJson());
  }

  @override
  AuthSessionModel? getCachedSession() {
    final raw = storage.read(_storageKey);
    if (raw is Map<String, dynamic>) {
      return AuthSessionModel.fromJson(raw);
    }
    return null;
  }

  @override
  Future<void> clearSession() async {
    await storage.remove(_storageKey);
  }
}
