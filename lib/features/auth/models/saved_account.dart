class SavedAccount {
  final String email;
  final String password;
  final String? userId;
  final String? role;
  final String? accessToken;

  const SavedAccount({
    required this.email,
    required this.password,
    this.userId,
    this.role,
    this.accessToken,
  });

  SavedAccount copyWith({
    String? email,
    String? password,
    String? userId,
    String? role,
    String? accessToken,
  }) {
    return SavedAccount(
      email: email ?? this.email,
      password: password ?? this.password,
      userId: userId ?? this.userId,
      role: role ?? this.role,
      accessToken: accessToken ?? this.accessToken,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
      'userId': userId,
      'role': role,
      'accessToken': accessToken,
    };
  }

  factory SavedAccount.fromJson(Map<String, dynamic> json) {
    return SavedAccount(
      email: json['email']?.toString() ?? '',
      password: json['password']?.toString() ?? '',
      userId: json['userId']?.toString(),
      role: json['role']?.toString(),
      accessToken: json['accessToken']?.toString(),
    );
  }
}
