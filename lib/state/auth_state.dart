import 'package:flutter_riverpod/flutter_riverpod.dart';

enum UserRole { admin, farmer, exporter, trader }

UserRole parseUserRole(String? role) {
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

class AuthState {
  final bool isLoggedIn;
  final UserRole? role;
  final String? userId;
  final String? email;
  final String? accessToken;

  const AuthState({
    required this.isLoggedIn,
    this.role,
    this.userId,
    this.email,
    this.accessToken,
  });

  AuthState copyWith({
    bool? isLoggedIn,
    UserRole? role,
    String? userId,
    String? email,
    String? accessToken,
  }) {
    return AuthState(
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      role: role ?? this.role,
      userId: userId ?? this.userId,
      email: email ?? this.email,
      accessToken: accessToken ?? this.accessToken,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState(isLoggedIn: false));

  void login({
    required String userId,
    required UserRole role,
    required String email,
    required String accessToken,
  }) {
    state = AuthState(
      isLoggedIn: true,
      role: role,
      userId: userId,
      email: email,
      accessToken: accessToken,
    );
  }

  void logout() {
    state = const AuthState(isLoggedIn: false);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
