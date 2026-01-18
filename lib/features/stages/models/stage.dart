class Stage {
  final int id;
  final String name;
  final int sequence;
  final bool active;

  Stage({
    required this.id,
    required this.name,
    required this.sequence,
    required this.active,
  });

  factory Stage.fromApi(Map<String, dynamic> json) {
    return Stage(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name']?.toString() ?? '',
      sequence: (json['sequence'] as num?)?.toInt() ?? 0,
      active: json['active'] == true,
    );
  }
}
