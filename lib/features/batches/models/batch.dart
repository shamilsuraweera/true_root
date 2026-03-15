class Batch {
  final String id;
  final String? productName;
  final String? itemName;
  final bool isItem;
  final int? productId;
  final String? ownerId;
  final String? ownerName;
  final String? ownerEmail;
  final double quantity;
  final String unit;
  final String status;
  final String? grade;
  final int? stageId;
  final bool isDisqualified;
  final DateTime createdAt;

  Batch({
    required this.id,
    this.productName,
    this.itemName,
    this.isItem = false,
    this.productId,
    this.ownerId,
    this.ownerName,
    this.ownerEmail,
    required this.quantity,
    this.unit = 'kg',
    required this.status,
    this.grade,
    this.stageId,
    this.isDisqualified = false,
    required this.createdAt,
  });

  String get displayProduct {
    if (itemName != null && itemName!.isNotEmpty) {
      return itemName!;
    }
    if (productName != null && productName!.isNotEmpty) {
      return productName!;
    }
    return 'Unknown product';
  }

  factory Batch.fromApi(Map<String, dynamic> json) {
    return Batch(
      id: json['id'].toString(),
      productId: json['productId'] is int
          ? json['productId'] as int
          : int.tryParse(json['productId']?.toString() ?? ''),
      productName: json['productName']?.toString(),
      itemName: json['itemName']?.toString(),
      isItem: json['isItem'] == true || json['isItem']?.toString() == 'true',
      ownerId: json['ownerId']?.toString(),
      ownerName: json['owner']?['name']?.toString(),
      ownerEmail: json['owner']?['email']?.toString(),
      quantity: _toDouble(json['quantity']) ?? 0,
      unit: json['unit']?.toString() ?? 'kg',
      status: json['status']?.toString() ?? 'UNKNOWN',
      grade: json['grade']?.toString(),
      stageId: json['stageId'] is int
          ? json['stageId'] as int
          : int.tryParse(json['stageId']?.toString() ?? ''),
      isDisqualified:
          json['isDisqualified'] == true ||
          json['isDisqualified']?.toString() == 'true',
      createdAt: DateTime.parse(
        json['createdAt']?.toString() ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  static double? _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value?.toString() ?? '');
  }
}
