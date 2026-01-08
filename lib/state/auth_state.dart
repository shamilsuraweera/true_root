import 'package:flutter_riverpod/flutter_riverpod.dart';

enum UserRole { admin, user }

class AuthState {
  final bool isLoggedIn;
  final UserRole? role;

  const AuthState({required this.isLoggedIn, this.role});

  AuthState copyWith({bool? isLoggedIn, UserRole? role}) {
    return AuthState(
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      role: role ?? this.role,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState(isLoggedIn: false));

  /// DEV / MOCK LOGIN — NO VALIDATION
  void login({UserRole role = UserRole.admin}) {
    state = AuthState(isLoggedIn: true, role: role);
  }

  void logout() {
    state = const AuthState(isLoggedIn: false);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
