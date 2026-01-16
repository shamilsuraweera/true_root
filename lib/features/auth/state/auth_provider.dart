import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../state/auth_state.dart';
import '../data/auth_api.dart';

final authApiProvider = Provider<AuthApi>((ref) {
  return AuthApi();
});

final authControllerProvider = Provider<AuthController>((ref) {
  final api = ref.read(authApiProvider);
  final authNotifier = ref.read(authProvider.notifier);
  return AuthController(api, authNotifier);
});

class AuthController {
  AuthController(this.api, this.authNotifier);

  final AuthApi api;
  final AuthNotifier authNotifier;

  Future<void> login(String email, String password) async {
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
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String role,
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
  }

  UserRole _parseRole(String? role) {
    switch (role) {
      case 'admin':
        return UserRole.admin;
      case 'farmer':
        return UserRole.farmer;
      case 'exporter':
        return UserRole.exporter;
      case 'trader':
        return UserRole.trader;
      default:
        return UserRole.farmer;
    }
  }
}
