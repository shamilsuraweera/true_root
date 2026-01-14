class OwnershipRequest {
  final String id;
  final String batchId;
  final String requesterId;
  final String ownerId;
  final double quantity;
  final String status;
  final String? note;
  final String createdAt;

  OwnershipRequest({
    required this.id,
    required this.batchId,
    required this.requesterId,
    required this.ownerId,
    required this.quantity,
    required this.status,
    this.note,
    required this.createdAt,
  });

  factory OwnershipRequest.fromApi(Map<String, dynamic> json) {
    return OwnershipRequest(
      id: json['id']?.toString() ?? '',
      batchId: json['batchId']?.toString() ?? '',
      requesterId: json['requesterId']?.toString() ?? '',
      ownerId: json['ownerId']?.toString() ?? '',
      quantity: _toDouble(json['quantity']) ?? 0,
      status: json['status']?.toString() ?? 'PENDING',
      note: json['note']?.toString(),
      createdAt: json['createdAt']?.toString() ?? '',
    );
  }

  static double? _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value?.toString() ?? '');
  }
}
