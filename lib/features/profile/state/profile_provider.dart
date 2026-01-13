import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../users/models/user.dart';
import '../../users/state/users_provider.dart';

final currentUserIdProvider = Provider<String>((ref) {
  return '1';
});

final profileProvider = FutureProvider<AppUser>((ref) async {
  final api = ref.read(usersApiProvider);
  final userId = ref.read(currentUserIdProvider);
  return api.fetchUser(userId);
});
