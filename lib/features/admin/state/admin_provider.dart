import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../home/models/recent_activity.dart';
import '../data/admin_api.dart';
import '../models/admin_overview.dart';
import '../../../state/auth_state.dart';

final adminApiProvider = Provider<AdminApi>((ref) {
  final token = ref.watch(authProvider).accessToken;
  return AdminApi(authToken: token);
});

final adminOverviewProvider = FutureProvider<AdminOverview>((ref) async {
  final api = ref.watch(adminApiProvider);
  return api.fetchOverview(limit: 10);
});

final adminRecentActivityProvider = Provider<List<RecentActivity>>((ref) {
  final overview = ref.watch(adminOverviewProvider).valueOrNull;
  return overview?.recentActivity ?? const [];
});
