import 'package:shared_preferences/shared_preferences.dart';

/// Service for storing and retrieving authentication tokens
/// UPDATED: Now stores complete tenant information for invoice creation
class TokenStorage {
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userIdKey = 'user_id';
  static const String _userEmailKey = 'user_email';
  static const String _userNameKey = 'user_name';
  static const String _tenantIdKey = 'tenant_id';
  static const String _tenantNameKey = 'tenant_name';

  // NEW: Additional tenant keys for invoice creation
  static const String _tenantStateKey = 'tenant_state';
  static const String _tenantCityKey = 'tenant_city';
  static const String _tenantEmailKey = 'tenant_email';
  static const String _tenantPhoneKey = 'tenant_phone';
  static const String _tenantAddressKey = 'tenant_address';
  static const String _tenantPincodeKey = 'tenant_pincode';
  static const String _tenantGstinKey = 'tenant_gstin';

  /// Save authentication tokens and user info
  /// UPDATED: Now accepts additional tenant fields (optional for backward compatibility)
  static Future<void> saveAuthData({
    required String accessToken,
    required String refreshToken,
    required int userId,
    required String userEmail,
    required String userName,
    required int tenantId,
    required String tenantName,
    // NEW: Optional tenant fields
    String? tenantState,
    String? tenantCity,
    String? tenantEmail,
    String? tenantPhone,
    String? tenantAddress,
    String? tenantPincode,
    String? tenantGstin,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    // Original fields
    await prefs.setString(_accessTokenKey, accessToken);
    await prefs.setString(_refreshTokenKey, refreshToken);
    await prefs.setInt(_userIdKey, userId);
    await prefs.setString(_userEmailKey, userEmail);
    await prefs.setString(_userNameKey, userName);
    await prefs.setInt(_tenantIdKey, tenantId);
    await prefs.setString(_tenantNameKey, tenantName);

    // NEW: Save additional tenant fields if provided
    if (tenantState != null) {
      await prefs.setString(_tenantStateKey, tenantState);
    }
    if (tenantCity != null) {
      await prefs.setString(_tenantCityKey, tenantCity);
    }
    if (tenantEmail != null) {
      await prefs.setString(_tenantEmailKey, tenantEmail);
    }
    if (tenantPhone != null) {
      await prefs.setString(_tenantPhoneKey, tenantPhone);
    }
    if (tenantAddress != null) {
      await prefs.setString(_tenantAddressKey, tenantAddress);
    }
    if (tenantPincode != null) {
      await prefs.setString(_tenantPincodeKey, tenantPincode);
    }
    if (tenantGstin != null) {
      await prefs.setString(_tenantGstinKey, tenantGstin);
    }
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

  // ==================== NEW: Additional Tenant Getters ====================

  /// Get tenant state (for tax calculation)
  static Future<String?> getTenantState() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tenantStateKey);
  }

  /// Get tenant city
  static Future<String?> getTenantCity() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tenantCityKey);
  }

  /// Get tenant email
  static Future<String?> getTenantEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tenantEmailKey);
  }

  /// Get tenant phone
  static Future<String?> getTenantPhone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tenantPhoneKey);
  }

  /// Get tenant address
  static Future<String?> getTenantAddress() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tenantAddressKey);
  }

  /// Get tenant pincode
  static Future<String?> getTenantPincode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tenantPincodeKey);
  }

  /// Get tenant GSTIN (for tax calculation)
  static Future<String?> getTenantGstin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tenantGstinKey);
  }

  /// Check if user is logged in (has access token)
  static Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  /// Clear all stored data (logout)
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    // Keep your original logic using remove instead of clear
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_userEmailKey);
    await prefs.remove(_userNameKey);
    await prefs.remove(_tenantIdKey);
    await prefs.remove(_tenantNameKey);
    // NEW: Remove additional tenant fields
    await prefs.remove(_tenantStateKey);
    await prefs.remove(_tenantCityKey);
    await prefs.remove(_tenantEmailKey);
    await prefs.remove(_tenantPhoneKey);
    await prefs.remove(_tenantAddressKey);
    await prefs.remove(_tenantPincodeKey);
    await prefs.remove(_tenantGstinKey);
  }
}
