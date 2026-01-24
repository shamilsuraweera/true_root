class SavedAccount {
  final String email;
  final String? userId;
  final String? role;
  final String? accessToken;

  const SavedAccount({
    required this.email,
    this.userId,
    this.role,
    this.accessToken,
  });

  SavedAccount copyWith({
    String? email,
    String? userId,
    String? role,
    String? accessToken,
  }) {
    return SavedAccount(
      email: email ?? this.email,
      userId: userId ?? this.userId,
      role: role ?? this.role,
      accessToken: accessToken ?? this.accessToken,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'userId': userId,
      'role': role,
    };
  }

  factory SavedAccount.fromJson(Map<String, dynamic> json) {
    return SavedAccount(
      email: json['email']?.toString() ?? '',
      userId: json['userId']?.toString(),
      role: json['role']?.toString(),
    );
  }
}
