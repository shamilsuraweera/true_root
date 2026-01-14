import 'package:flutter_riverpod/flutter_riverpod.dart';

enum UserRole { admin, farmer, exporter, trader }

class AuthState {
  final bool isLoggedIn;
  final UserRole? role;
  final String? userId;
  final String? email;

  const AuthState({
    required this.isLoggedIn,
    this.role,
    this.userId,
    this.email,
  });

  AuthState copyWith({
    bool? isLoggedIn,
    UserRole? role,
    String? userId,
    String? email,
  }) {
    return AuthState(
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      role: role ?? this.role,
      userId: userId ?? this.userId,
      email: email ?? this.email,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState(isLoggedIn: false));

  void login({
    required String userId,
    required UserRole role,
    required String email,
  }) {
    state = AuthState(isLoggedIn: true, role: role, userId: userId, email: email);
  }

  void logout() {
    state = const AuthState(isLoggedIn: false);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
