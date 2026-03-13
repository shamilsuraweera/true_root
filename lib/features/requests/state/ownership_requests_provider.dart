import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../profile/state/profile_provider.dart';
import '../data/ownership_requests_api.dart';
import '../models/ownership_request.dart';
import '../../../state/auth_state.dart';

final ownershipRequestsApiProvider = Provider<OwnershipRequestsApi>((ref) {
  final token = ref.watch(authProvider).accessToken;
  return OwnershipRequestsApi(authToken: token);
});

final cachedOwnershipInboxProvider =
    StateProvider<List<OwnershipRequest>>((ref) => const []);
final ownershipInboxProvider = FutureProvider<List<OwnershipRequest>>((ref) async {
  final api = ref.watch(ownershipRequestsApiProvider);
  final ownerId = ref.read(currentUserIdProvider);
  final items = await api.fetchInbox(ownerId);
  ref.read(cachedOwnershipInboxProvider.notifier).state = items;
  return items;
});

final cachedOwnershipOutboxProvider =
    StateProvider<List<OwnershipRequest>>((ref) => const []);
final ownershipOutboxProvider = FutureProvider<List<OwnershipRequest>>((ref) async {
  final api = ref.watch(ownershipRequestsApiProvider);
  final requesterId = ref.read(currentUserIdProvider);
  final items = await api.fetchOutbox(requesterId);
  ref.read(cachedOwnershipOutboxProvider.notifier).state = items;
  return items;
});
