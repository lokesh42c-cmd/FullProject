import 'package:shared_preferences/shared_preferences.dart';

/// Service for storing and retrieving authentication tokens
class TokenStorage {
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userIdKey = 'user_id';
  static const String _userEmailKey = 'user_email';
  static const String _userNameKey = 'user_name';
  static const String _tenantIdKey = 'tenant_id';
  static const String _tenantNameKey = 'tenant_name';

  /// Save authentication tokens and user info
  static Future<void> saveAuthData({
    required String accessToken,
    required String refreshToken,
    required int userId,
    required String userEmail,
    required String userName,
    required int tenantId,
    required String tenantName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessTokenKey, accessToken);
    await prefs.setString(_refreshTokenKey, refreshToken);
    await prefs.setInt(_userIdKey, userId);
    await prefs.setString(_userEmailKey, userEmail);
    await prefs.setString(_userNameKey, userName);
    await prefs.setInt(_tenantIdKey, tenantId);
    await prefs.setString(_tenantNameKey, tenantName);
  }

  /// Get access token
  static Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_accessTokenKey);
  }

  /// Get refresh token
  static Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshTokenKey);
  }

  /// Get user ID
  static Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_userIdKey);
  }

  /// Get user email
  static Future<String?> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userEmailKey);
  }

  /// Get user name
  static Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userNameKey);
  }

  /// Get tenant ID
  static Future<int?> getTenantId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_tenantIdKey);
  }

  /// Get tenant name
  static Future<String?> getTenantName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tenantNameKey);
  }

  /// Check if user is logged in (has access token)
  static Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  /// Clear all stored data (logout)
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_userEmailKey);
    await prefs.remove(_userNameKey);
    await prefs.remove(_tenantIdKey);
    await prefs.remove(_tenantNameKey);
  }
}
