class AppUser {
  final String id;
  final String email;
  final String role;
  final String? name;
  final String? organization;
  final String? location;

  AppUser({
    required this.id,
    required this.email,
    required this.role,
    this.name,
    this.organization,
    this.location,
  });

  String get displayName => name?.isNotEmpty == true ? name! : email;

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

  String get organization => this.organization?.isNotEmpty == true ? this.organization! : 'No org';

  String get location => this.location?.isNotEmpty == true ? this.location! : 'Unknown';

  bool matches(String query) {
    return displayName.toLowerCase().contains(query) ||
        email.toLowerCase().contains(query) ||
        organization.toLowerCase().contains(query) ||
        roleLabel.toLowerCase().contains(query) ||
        location.toLowerCase().contains(query);
  }

  factory AppUser.fromApi(Map<String, dynamic> json) {
    return AppUser(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      name: json['name']?.toString(),
      organization: json['organization']?.toString(),
      location: json['location']?.toString(),
    );
  }
}
