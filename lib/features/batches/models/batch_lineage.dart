import 'batch.dart';

class BatchLineage {
  final List<BatchRelationItem> parents;
  final List<BatchRelationItem> children;

  const BatchLineage({
    required this.parents,
    required this.children,
  });

  factory BatchLineage.fromApi(Map<String, dynamic> json) {
    final parents = (json['parents'] as List<dynamic>? ?? [])
        .map((item) => BatchRelationItem.fromApi(item as Map<String, dynamic>))
        .toList();
    final children = (json['children'] as List<dynamic>? ?? [])
        .map((item) => BatchRelationItem.fromApi(item as Map<String, dynamic>))
        .toList();
    return BatchLineage(parents: parents, children: children);
  }
}

class BatchRelationItem {
  final String id;
  final String parentBatchId;
  final String childBatchId;
  final String relationType;
  final double? quantity;
  final DateTime createdAt;
  final Batch? batch;

  BatchRelationItem({
    required this.id,
    required this.parentBatchId,
    required this.childBatchId,
    required this.relationType,
    required this.quantity,
    required this.createdAt,
    this.batch,
  });

  factory BatchRelationItem.fromApi(Map<String, dynamic> json) {
    final batchJson = json['batch'];
    return BatchRelationItem(
      id: json['id'].toString(),
      parentBatchId: json['parentBatchId'].toString(),
      childBatchId: json['childBatchId'].toString(),
      relationType: json['relationType']?.toString() ?? 'UNKNOWN',
      quantity: _toDouble(json['quantity']),
      createdAt: DateTime.parse(json['createdAt']?.toString() ?? DateTime.now().toIso8601String()),
      batch: batchJson is Map<String, dynamic> ? Batch.fromApi(batchJson) : null,
    );
  }

  static double? _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value?.toString() ?? '');
  }
}
