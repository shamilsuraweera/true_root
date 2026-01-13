class RecentActivity {
  final String title;
  final String subtitle;

  RecentActivity({
    required this.title,
    required this.subtitle,
  });

  factory RecentActivity.fromApi(Map<String, dynamic> json) {
    final type = json['type']?.toString() ?? 'EVENT';
    final batchId = json['batchId']?.toString() ?? '-';
    final description = json['description']?.toString();
    final createdAt = json['createdAt']?.toString();

    final title = _titleFromType(type);
    final subtitleParts = <String>[
      'Batch $batchId',
      if (createdAt != null) _formatTime(createdAt),
      if (description != null && description.isNotEmpty) description,
    ];

    return RecentActivity(
      title: title,
      subtitle: subtitleParts.join(' • '),
    );
  }

  static String _titleFromType(String type) {
    switch (type) {
      case 'CREATED':
        return 'Created batch';
      case 'QUANTITY_CHANGED':
        return 'Updated quantity';
      case 'STATUS_CHANGED':
        return 'Updated status';
      case 'GRADE_CHANGED':
        return 'Updated grade';
      case 'DISQUALIFIED':
        return 'Disqualified batch';
      case 'SPLIT':
        return 'Split batch';
      case 'MERGED':
        return 'Merged batches';
      case 'TRANSFORMED':
        return 'Transformed batch';
      default:
        return 'Batch update';
    }
  }

  static String _formatTime(String iso) {
    final date = DateTime.tryParse(iso);
    if (date == null) return iso;
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
