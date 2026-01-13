class Batch {
  final String id;
  final String? productName;
  final int? productId;
  final double quantity;
  final String unit;
  final String status;
  final String? grade;
  final DateTime createdAt;

  Batch({
    required this.id,
    this.productName,
    this.productId,
    required this.quantity,
    this.unit = 'kg',
    required this.status,
    this.grade,
    required this.createdAt,
  });

  String get displayProduct {
    if (productName != null && productName!.isNotEmpty) {
      return productName!;
    }
    if (productId != null) {
      return 'Product #$productId';
    }
    return 'Unknown product';
  }

  factory Batch.fromApi(Map<String, dynamic> json) {
    return Batch(
      id: json['id'].toString(),
      productId: json['productId'] is int ? json['productId'] as int : int.tryParse(json['productId']?.toString() ?? ''),
      quantity: _toDouble(json['quantity']) ?? 0,
      unit: json['unit']?.toString() ?? 'kg',
      status: json['status']?.toString() ?? 'UNKNOWN',
      grade: json['grade']?.toString(),
      createdAt: DateTime.parse(json['createdAt']?.toString() ?? DateTime.now().toIso8601String()),
    );
  }

  static double? _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value?.toString() ?? '');
  }
}
