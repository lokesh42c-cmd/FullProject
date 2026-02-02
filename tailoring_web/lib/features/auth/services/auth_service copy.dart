import 'package:tailoring_web/core/api/api_client.dart';

/// Authentication Service
class AuthService {
  final ApiClient _apiClient;

  AuthService(this._apiClient);

  /// Login with email and password
  Future<LoginResponse> login({
    required String email,
    required String password,
  }) async {
    final response = await _apiClient.post(
      'auth/login/', //
      data: {'email': email, 'password': password},
    );

    final loginResponse = LoginResponse.fromJson(response.data);
    _apiClient.setAccessToken(loginResponse.tokens.access);
    return loginResponse;
  }

  /// Register new user/tenant
  Future<LoginResponse> register({
    required String businessName,
    required String ownerName,
    required String email,
    required String phone,
    required String password,
  }) async {
    final response = await _apiClient.post(
      'auth/register/',
      data: {
        'business_name': businessName,
        'owner_name': ownerName,
        'email': email,
        'phone': phone,
        'password': password,
      },
    );

    final loginResponse = LoginResponse.fromJson(response.data);
    _apiClient.setAccessToken(loginResponse.tokens.access);
    return loginResponse;
  }

  /// Refresh access token
  Future<String> refreshToken(String refreshToken) async {
    final response = await _apiClient.post(
      'token/refresh/',
      data: {'refresh': refreshToken},
    );

    final newAccessToken = response.data['access'] as String;
    _apiClient.setAccessToken(newAccessToken);
    return newAccessToken;
  }

  /// Logout
  void logout() {
    _apiClient.clearAccessToken();
  }

  /// Check if authenticated
  bool get isAuthenticated => _apiClient.accessToken != null;

  /// Set access token
  void setAccessToken(String token) {
    _apiClient.setAccessToken(token);
  }
}

/// Login response model
class LoginResponse {
  final String message;
  final User user;
  final Tokens tokens;

  LoginResponse({
    required this.message,
    required this.user,
    required this.tokens,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      message: json['message'] as String,
      user: User.fromJson(json['user'] as Map<String, dynamic>),
      tokens: Tokens.fromJson(json['tokens'] as Map<String, dynamic>),
    );
  }
}

class User {
  final int id;
  final String email;
  final String name;
  final Tenant tenant;

  User({
    required this.id,
    required this.email,
    required this.name,
    required this.tenant,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      email: json['email'] as String,
      name: json['name'] as String,
      tenant: Tenant.fromJson(json['tenant'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'email': email, 'name': name, 'tenant': tenant.toJson()};
  }
}

class Tenant {
  final int id;
  final String name;

  Tenant({required this.id, required this.name});

  factory Tenant.fromJson(Map<String, dynamic> json) {
    return Tenant(id: json['id'] as int, name: json['name'] as String);
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name};
  }
}

class Tokens {
  final String refresh;
  final String access;

  Tokens({required this.refresh, required this.access});

  factory Tokens.fromJson(Map<String, dynamic> json) {
    return Tokens(
      refresh: json['refresh'] as String,
      access: json['access'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {'refresh': refresh, 'access': access};
  }
}
