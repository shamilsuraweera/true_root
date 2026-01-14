import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../profile/state/profile_provider.dart';
import '../data/ownership_requests_api.dart';
import '../models/ownership_request.dart';

final ownershipRequestsApiProvider = Provider<OwnershipRequestsApi>((ref) {
  return OwnershipRequestsApi();
});

final ownershipInboxProvider = FutureProvider<List<OwnershipRequest>>((ref) async {
  final api = ref.read(ownershipRequestsApiProvider);
  final ownerId = ref.read(currentUserIdProvider);
  return api.fetchInbox(ownerId);
});

final ownershipOutboxProvider = FutureProvider<List<OwnershipRequest>>((ref) async {
  final api = ref.read(ownershipRequestsApiProvider);
  final requesterId = ref.read(currentUserIdProvider);
  return api.fetchOutbox(requesterId);
});
