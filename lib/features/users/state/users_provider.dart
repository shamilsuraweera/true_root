import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/users_api.dart';
import '../models/user.dart';
import '../../../state/auth_state.dart';

final usersApiProvider = Provider<UsersApi>((ref) {
  final token = ref.watch(authProvider).accessToken;
  return UsersApi(authToken: token);
});

final usersListProvider = FutureProvider<List<AppUser>>((ref) async {
  final api = ref.watch(usersApiProvider);
  return api.fetchUsers();
});
