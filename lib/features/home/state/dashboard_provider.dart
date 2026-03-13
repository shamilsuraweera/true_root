import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../batches/models/batch.dart';
import '../../batches/state/batch_provider.dart';
import '../data/dashboard_api.dart';
import '../models/recent_activity.dart';
import '../../profile/state/profile_provider.dart';
import '../../requests/models/ownership_request.dart';
import '../../../state/auth_state.dart';

final dashboardApiProvider = Provider<DashboardApi>((ref) {
  final token = ref.watch(authProvider).accessToken;
  return DashboardApi(authToken: token);
});

final cachedPendingRequestsProvider =
    StateProvider<List<OwnershipRequest>>((ref) => const []);
final pendingRequestsProvider = FutureProvider<List<OwnershipRequest>>((ref) async {
  final api = ref.watch(dashboardApiProvider);
  final ownerId = ref.read(currentUserIdProvider);
  final items = await api.fetchPendingRequests(ownerId: ownerId, limit: 5);
  ref.read(cachedPendingRequestsProvider.notifier).state = items;
  return items;
});

final cachedRecentActivityProvider =
    StateProvider<List<RecentActivity>>((ref) => const []);
final recentActivityProvider = FutureProvider<List<RecentActivity>>((ref) async {
  final api = ref.watch(dashboardApiProvider);
  final ownerId = ref.read(currentUserIdProvider);
  final items = await api.fetchRecentActivity(limit: 5, ownerId: ownerId);
  ref.read(cachedRecentActivityProvider.notifier).state = items;
  return items;
});

final cachedRecentBatchesProvider =
    StateProvider<List<Batch>>((ref) => const []);
final recentBatchesProvider = FutureProvider<List<Batch>>((ref) async {
  final api = ref.watch(batchApiProvider);
  final ownerId = ref.read(currentUserIdProvider);
  final items = await api.fetchBatches(limit: 5, ownerId: ownerId);
  ref.read(cachedRecentBatchesProvider.notifier).state = items;
  return items;
});

final dashboardSearchProvider = StateProvider<String>((ref) => '');
