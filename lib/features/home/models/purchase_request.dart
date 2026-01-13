class PurchaseRequest {
  final String requesterName;
  final String batchId;
  final String quantity;

  PurchaseRequest({
    required this.requesterName,
    required this.batchId,
    required this.quantity,
  });

  factory PurchaseRequest.fromApi(Map<String, dynamic> json) {
    return PurchaseRequest(
      requesterName: json['requesterName']?.toString() ?? 'Unknown',
      batchId: json['batchId']?.toString() ?? '-',
      quantity: json['quantity']?.toString() ?? '-',
    );
  }
}
