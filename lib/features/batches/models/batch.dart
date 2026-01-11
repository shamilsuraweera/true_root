class Batch {
  final String id;
  final String product;
  final double quantity;
  final String status;
  final DateTime createdAt;

  Batch({
    required this.id,
    required this.product,
    required this.quantity,
    required this.status,
    required this.createdAt,
  });
}
