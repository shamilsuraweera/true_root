import '../../home/models/recent_activity.dart';

class AdminOverview {
  final int users;
  final int products;
  final int stages;
  final int batches;
  final List<RecentActivity> recentActivity;

  const AdminOverview({
    required this.users,
    required this.products,
    required this.stages,
    required this.batches,
    required this.recentActivity,
  });

  factory AdminOverview.fromApi(Map<String, dynamic> json) {
    final counts = json['counts'] as Map<String, dynamic>? ?? {};
    final events = json['recentEvents'] as List<dynamic>? ?? [];
    return AdminOverview(
      users: (counts['users'] as num?)?.toInt() ?? 0,
      products: (counts['products'] as num?)?.toInt() ?? 0,
      stages: (counts['stages'] as num?)?.toInt() ?? 0,
      batches: (counts['batches'] as num?)?.toInt() ?? 0,
      recentActivity: events
          .map((item) => RecentActivity.fromApi(item as Map<String, dynamic>))
          .toList(),
    );
  }
}
