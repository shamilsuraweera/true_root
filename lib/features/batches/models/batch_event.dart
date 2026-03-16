class BatchEvent {
  final String id;
  final String type;
  final String? description;
  final DateTime createdAt;

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
      createdAt: DateTime.parse(
        json['createdAt']?.toString() ?? DateTime.now().toIso8601String(),
      ),
    );
  }
}
