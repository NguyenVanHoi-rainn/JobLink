class AuthUser {
  final String id;
  final String role;

  const AuthUser({
    required this.id,
    required this.role,
  });

  factory AuthUser.fromJson(
      Map<String, dynamic> json,
      ) {
    return AuthUser(
      id:
      json['id']?.toString() ??
          json['sub']?.toString() ??
          '',
      role:
      json['role']?.toString() ??
          '',
    );
  }
}