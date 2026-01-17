import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../state/auth_state.dart';
import '../data/auth_api.dart';
import '../../../core/storage/auth_storage.dart';
import '../models/saved_account.dart';

final authApiProvider = Provider<AuthApi>((ref) {
  return AuthApi();
});

final authStorageProvider = Provider<AuthStorage>((ref) {
  return AuthStorage();
});

final authControllerProvider = Provider<AuthController>((ref) {
  final api = ref.read(authApiProvider);
  final authNotifier = ref.read(authProvider.notifier);
  final storage = ref.read(authStorageProvider);
  return AuthController(api, authNotifier, storage);
});

class AuthController {
  AuthController(this.api, this.authNotifier, this.storage);

  final AuthApi api;
  final AuthNotifier authNotifier;
  final AuthStorage storage;

  Future<void> login(
    String email,
    String password, {
    bool remember = true,
  }) async {
    final response = await api.login(email, password);
    final user = response['user'] as Map<String, dynamic>;
    final token = response['accessToken'] as String?;
    if (token == null || token.isEmpty) {
      throw Exception('Missing access token');
    }
    authNotifier.login(
      userId: user['id'].toString(),
      role: _parseRole(user['role']?.toString()),
      email: email,
      accessToken: token,
    );

    if (remember) {
      await storage.upsertAccount(
        SavedAccount(
          email: email,
          password: password,
          userId: user['id']?.toString(),
          role: user['role']?.toString(),
          accessToken: token,
        ),
      );
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String role,
    bool remember = true,
  }) async {
    final response = await api.register(
      email: email,
      password: password,
      role: role,
      name: name,
    );
    final user = response['user'] as Map<String, dynamic>;
    final token = response['accessToken'] as String?;
    if (token == null || token.isEmpty) {
      throw Exception('Missing access token');
    }
    authNotifier.login(
      userId: user['id'].toString(),
      role: _parseRole(user['role']?.toString()),
      email: email,
      accessToken: token,
    );

    if (remember) {
      await storage.upsertAccount(
        SavedAccount(
          email: email,
          password: password,
          userId: user['id']?.toString(),
          role: user['role']?.toString(),
          accessToken: token,
        ),
      );
    }
  }

  UserRole _parseRole(String? role) {
    return parseUserRole(role);
  }
}
