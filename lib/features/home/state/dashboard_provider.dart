import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../batches/models/batch.dart';
import '../../batches/state/batch_provider.dart';
import '../data/dashboard_api.dart';
import '../models/purchase_request.dart';
import '../models/recent_activity.dart';

final dashboardApiProvider = Provider<DashboardApi>((ref) {
  return DashboardApi();
});

final pendingRequestsProvider = FutureProvider<List<PurchaseRequest>>((ref) async {
  final api = ref.read(dashboardApiProvider);
  return api.fetchPendingRequests(limit: 5);
});

final recentActivityProvider = FutureProvider<List<RecentActivity>>((ref) async {
  final api = ref.read(dashboardApiProvider);
  return api.fetchRecentActivity(limit: 5);
});

final recentBatchesProvider = FutureProvider<List<Batch>>((ref) async {
  final api = ref.read(batchApiProvider);
  return api.fetchBatches(limit: 5);
});
