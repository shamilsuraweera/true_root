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

final pendingRequestsProvider = FutureProvider<List<OwnershipRequest>>((ref) async {
  final api = ref.watch(dashboardApiProvider);
  final ownerId = ref.read(currentUserIdProvider);
  return api.fetchPendingRequests(ownerId: ownerId, limit: 5);
});

final recentActivityProvider = FutureProvider<List<RecentActivity>>((ref) async {
  final api = ref.watch(dashboardApiProvider);
  final ownerId = ref.read(currentUserIdProvider);
  return api.fetchRecentActivity(limit: 5, ownerId: ownerId);
});

final recentBatchesProvider = FutureProvider<List<Batch>>((ref) async {
  final api = ref.watch(batchApiProvider);
  final ownerId = ref.read(currentUserIdProvider);
  return api.fetchBatches(limit: 5, ownerId: ownerId);
});

final dashboardSearchProvider = StateProvider<String>((ref) => '');
