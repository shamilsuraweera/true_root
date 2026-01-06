import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthState {
  final bool isLoggedIn;
  const AuthState({required this.isLoggedIn});
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState(isLoggedIn: false));

  void login() {
    state = const AuthState(isLoggedIn: true);
  }

  void logout() {
    state = const AuthState(isLoggedIn: false);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
