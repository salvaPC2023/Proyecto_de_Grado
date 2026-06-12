import '../../../domain/models/user.dart';

class LoginRequest {
  const LoginRequest({required this.username, required this.password});
  final String username;
  final String password;
  Map<String, dynamic> toJson() => {'username': username, 'password': password};
}

class LoginResponse {
  const LoginResponse({required this.accessToken, required this.tokenType, required this.user});
  final String accessToken;
  final String tokenType;
  final User user;

  factory LoginResponse.fromJson(Map<String, dynamic> json) => LoginResponse(
        accessToken: json['access_token'] as String,
        tokenType: json['token_type'] as String,
        user: User.fromJson(json['user'] as Map<String, dynamic>),
      );
}
