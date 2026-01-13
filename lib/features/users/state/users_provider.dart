import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/users_api.dart';
import '../models/user.dart';

final usersApiProvider = Provider<UsersApi>((ref) {
  return UsersApi();
});

final usersListProvider = FutureProvider<List<AppUser>>((ref) async {
  final api = ref.read(usersApiProvider);
  return api.fetchUsers();
});
