class AppUser {
  final String id;
  final String email;
  final String role;
  final String? name;
  final String? organization;
  final String? location;
  final String? accountType;
  final List<String> members;

  AppUser({
    required this.id,
    required this.email,
    required this.role,
    this.name,
    this.organization,
    this.location,
    this.accountType,
    this.members = const [],
  });

  String get displayName {
    final candidate = name;
    return candidate != null && candidate.isNotEmpty ? candidate : email;
  }

  String get roleLabel {
    switch (role) {
      case 'admin':
        return 'Admin';
      case 'farmer':
        return 'Farmer';
      case 'exporter':
        return 'Exporter';
      case 'trader':
        return 'Trader';
      default:
        return role.isEmpty ? 'User' : role;
    }
  }

  String get organizationLabel {
    final value = organization;
    return value != null && value.isNotEmpty ? value : 'No org';
  }

  String get locationLabel {
    final value = location;
    return value != null && value.isNotEmpty ? value : 'Unknown';
  }

  bool matches(String query) {
    return displayName.toLowerCase().contains(query) ||
        email.toLowerCase().contains(query) ||
        organizationLabel.toLowerCase().contains(query) ||
        roleLabel.toLowerCase().contains(query) ||
        locationLabel.toLowerCase().contains(query);
  }

  factory AppUser.fromApi(Map<String, dynamic> json) {
    final members = json['members'];
    return AppUser(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      name: json['name']?.toString(),
      organization: json['organization']?.toString(),
      location: json['location']?.toString(),
      accountType: json['accountType']?.toString(),
      members: members is List ? members.map((item) => item.toString()).toList() : const [],
    );
  }
}
