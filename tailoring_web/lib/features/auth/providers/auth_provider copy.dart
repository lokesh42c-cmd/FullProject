import 'package:flutter/foundation.dart';
import 'package:tailoring_web/core/api/api_client.dart';
import 'package:tailoring_web/core/storage/token_storage.dart';
import 'package:tailoring_web/features/auth/services/auth_service.dart';

/// Authentication state provider
class AuthProvider with ChangeNotifier {
  final AuthService _authService;

  bool _isLoading = false;
  bool _isAuthenticated = false;
  String? _errorMessage;

  // User info
  int? _userId;
  String? _userEmail;
  String? _userName;
  int? _tenantId;
  String? _tenantName;

  AuthProvider(this._authService);

  // Getters
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  String? get errorMessage => _errorMessage;
  int? get userId => _userId;
  String? get userEmail => _userEmail;
  String? get userName => _userName;
  int? get tenantId => _tenantId;
  String? get tenantName => _tenantName;

  /// Check if user is already logged in (on app start)
  Future<void> checkAuthStatus() async {
    _isLoading = true;
    notifyListeners();

    try {
      final isLoggedIn = await TokenStorage.isLoggedIn();

      if (isLoggedIn) {
        // Load user data from storage
        _userId = await TokenStorage.getUserId();
        _userEmail = await TokenStorage.getUserEmail();
        _userName = await TokenStorage.getUserName();
        _tenantId = await TokenStorage.getTenantId();
        _tenantName = await TokenStorage.getTenantName();

        // Restore access token to API client
        final accessToken = await TokenStorage.getAccessToken();
        if (accessToken != null && accessToken.isNotEmpty) {
          _authService.setAccessToken(accessToken);
        }

        _isAuthenticated = true;
      } else {
        _isAuthenticated = false;
      }
    } catch (e) {
      _isAuthenticated = false;
      _errorMessage = 'Failed to check authentication status';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Login with email and password
  Future<bool> login({required String email, required String password}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final loginResponse = await _authService.login(
        email: email,
        password: password,
      );

      // Save tokens and user info
      await TokenStorage.saveAuthData(
        accessToken: loginResponse.tokens.access,
        refreshToken: loginResponse.tokens.refresh,
        userId: loginResponse.user.id,
        userEmail: loginResponse.user.email,
        userName: loginResponse.user.name,
        tenantId: loginResponse.user.tenant.id,
        tenantName: loginResponse.user.tenant.name,
      );

      // Update state
      _userId = loginResponse.user.id;
      _userEmail = loginResponse.user.email;
      _userName = loginResponse.user.name;
      _tenantId = loginResponse.user.tenant.id;
      _tenantName = loginResponse.user.tenant.name;
      _isAuthenticated = true;

      _isLoading = false;
      notifyListeners();

      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isAuthenticated = false;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'An unexpected error occurred';
      _isAuthenticated = false;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Register new user
  Future<bool> register({
    required String businessName,
    required String ownerName,
    required String email,
    required String phone,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final loginResponse = await _authService.register(
        businessName: businessName,
        ownerName: ownerName,
        email: email,
        phone: phone,
        password: password,
      );

      // Save tokens and user info (same as login)
      await TokenStorage.saveAuthData(
        accessToken: loginResponse.tokens.access,
        refreshToken: loginResponse.tokens.refresh,
        userId: loginResponse.user.id,
        userEmail: loginResponse.user.email,
        userName: loginResponse.user.name,
        tenantId: loginResponse.user.tenant.id,
        tenantName: loginResponse.user.tenant.name,
      );

      // Update state
      _userId = loginResponse.user.id;
      _userEmail = loginResponse.user.email;
      _userName = loginResponse.user.name;
      _tenantId = loginResponse.user.tenant.id;
      _tenantName = loginResponse.user.tenant.name;
      _isAuthenticated = true;

      _isLoading = false;
      notifyListeners();

      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isAuthenticated = false;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'An unexpected error occurred during registration';
      _isAuthenticated = false;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Logout
  Future<void> logout() async {
    _authService.logout();
    await TokenStorage.clearAll();

    _isAuthenticated = false;
    _userId = null;
    _userEmail = null;
    _userName = null;
    _tenantId = null;
    _tenantName = null;
    _errorMessage = null;

    notifyListeners();
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
