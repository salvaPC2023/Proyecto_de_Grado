enum Role { supervisor, technician }

enum UserStatus { active, disabled }

class User {
  const User({
    required this.id,
    required this.username,
    required this.displayName,
    required this.role,
    required this.status,
  });

  final String id;
  final String username;
  final String displayName;
  final Role role;
  final UserStatus status;

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] as String,
        username: json['username'] as String,
        displayName: json['display_name'] as String,
        role: Role.values.byName(json['role'] as String),
        status: UserStatus.values.byName(json['status'] as String),
      );
}

class AuthSession {
  const AuthSession({required this.user, required this.token});
  final User user;
  final String token;
}
