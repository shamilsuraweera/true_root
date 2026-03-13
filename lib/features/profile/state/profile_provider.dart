import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../users/models/user.dart';
import '../../users/state/users_provider.dart';
import '../../../state/auth_state.dart';

final currentUserIdProvider = Provider<String>((ref) {
  final auth = ref.watch(authProvider);
  return auth.userId ?? '1';
});

final cachedProfileProvider = StateProvider<AppUser?>((ref) => null);
final profileProvider = FutureProvider<AppUser>((ref) async {
  final api = ref.watch(usersApiProvider);
  final userId = ref.read(currentUserIdProvider);
  final user = await api.fetchUser(userId);
  ref.read(cachedProfileProvider.notifier).state = user;
  return user;
});
