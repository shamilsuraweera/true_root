class BatchEvent {
  final String id;
  final String type;
  final String? description;
  final String createdAt;

  BatchEvent({
    required this.id,
    required this.type,
    this.description,
    required this.createdAt,
  });

  factory BatchEvent.fromApi(Map<String, dynamic> json) {
    return BatchEvent(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      description: json['description']?.toString(),
      createdAt: json['createdAt']?.toString() ?? '',
    );
  }
}
