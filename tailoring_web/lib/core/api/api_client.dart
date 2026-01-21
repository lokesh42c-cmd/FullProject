import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Base API client for all HTTP requests - SINGLETON PATTERN
///
/// Handles:
/// - JWT authentication (shared across app)
/// - Base URL configuration
/// - Request/response interceptors
/// - Error handling
/// - Logging
class ApiClient {
  // ==================== SINGLETON PATTERN ====================
  static final ApiClient _instance = ApiClient._internal();

  factory ApiClient() {
    return _instance;
  }

  ApiClient._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
        responseType: ResponseType.json, // ✅ CRITICAL FIX
        contentType: 'application/json',
        headers: {'Accept': 'application/json'},
      ),
    );

    // Add interceptors
    _dio.interceptors.add(_AuthInterceptor(this));
    _dio.interceptors.add(_LoggingInterceptor());
  }
  // ==================== END SINGLETON ====================

  late final Dio _dio;
  String? _accessToken;

  // Base URLs
  static const String productionBaseUrl = 'https://api.tailoringweb.com/api/';
  static const String developmentBaseUrl = 'http://localhost:8000/api/';

  /// Get the appropriate base URL based on environment
  static String get baseUrl {
    return kDebugMode ? developmentBaseUrl : productionBaseUrl;
  }

  /// Set access token for authenticated requests
  void setAccessToken(String? token) {
    _accessToken = token;
    if (kDebugMode) {
      print('🔑 Token set: ${token?.substring(0, 20)}...');
    }
  }

  /// Get current access token
  String? get accessToken => _accessToken;

  /// Clear access token (logout)
  void clearAccessToken() {
    _accessToken = null;
    if (kDebugMode) {
      print('🔓 Token cleared');
    }
  }

  /// GET request
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// POST request
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// PUT request
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// PATCH request
  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.patch<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// DELETE request
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Handle DioException and convert to ApiException
  ApiException _handleError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiException(
          message: 'Connection timeout. Please check your internet connection.',
          statusCode: null,
          type: ApiExceptionType.timeout,
        );

      case DioExceptionType.badResponse:
        final response = error.response;
        if (response != null) {
          return _parseErrorResponse(response);
        }
        return ApiException(
          message: 'Server error occurred',
          statusCode: response?.statusCode,
          type: ApiExceptionType.server,
        );

      case DioExceptionType.cancel:
        return ApiException(
          message: 'Request cancelled',
          statusCode: null,
          type: ApiExceptionType.cancel,
        );

      case DioExceptionType.connectionError:
        return ApiException(
          message: 'No internet connection',
          statusCode: null,
          type: ApiExceptionType.network,
        );

      default:
        return ApiException(
          message: 'An unexpected error occurred: ${error.message}',
          statusCode: null,
          type: ApiExceptionType.unknown,
        );
    }
  }

  /// Parse error response from server
  ApiException _parseErrorResponse(Response response) {
    final statusCode = response.statusCode;
    final data = response.data;

    String message = 'An error occurred';
    Map<String, List<String>>? fieldErrors;

    if (data is Map<String, dynamic>) {
      // Check for detail field (common in DRF)
      if (data.containsKey('detail')) {
        message = data['detail'].toString();
      }
      // Check for error field
      else if (data.containsKey('error')) {
        message = data['error'].toString();
      }
      // Check for field-specific errors (validation errors)
      else {
        fieldErrors = {};
        bool hasFieldErrors = false;
        data.forEach((key, value) {
          if (value is List) {
            fieldErrors![key] = value.map((e) => e.toString()).toList();
            hasFieldErrors = true;
          } else if (value is String) {
            fieldErrors![key] = [value];
            hasFieldErrors = true;
          }
        });

        if (hasFieldErrors) {
          // Create message from first error
          final firstError = fieldErrors.values.first.first;
          message = firstError;
        }
      }
    }

    // Determine exception type based on status code
    ApiExceptionType type;
    if (statusCode == 400) {
      type = ApiExceptionType.badRequest;
    } else if (statusCode == 401) {
      type = ApiExceptionType.unauthorized;
    } else if (statusCode == 403) {
      type = ApiExceptionType.forbidden;
    } else if (statusCode == 404) {
      type = ApiExceptionType.notFound;
    } else if (statusCode != null && statusCode >= 500) {
      type = ApiExceptionType.server;
    } else {
      type = ApiExceptionType.unknown;
    }

    return ApiException(
      message: message,
      statusCode: statusCode,
      type: type,
      fieldErrors: fieldErrors,
    );
  }
}

/// Auth interceptor to add JWT token to requests
class _AuthInterceptor extends Interceptor {
  final ApiClient _apiClient;

  _AuthInterceptor(this._apiClient);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Add authorization header if token exists
    if (_apiClient.accessToken != null) {
      options.headers['Authorization'] = 'Bearer ${_apiClient.accessToken}';
    }
    super.onRequest(options, handler);
  }
}

/// Logging interceptor for debugging
class _LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      print('🌐 REQUEST[${options.method}] => ${options.uri}');
      if (options.data != null) {
        print('📤 DATA: ${options.data}');
      }
    }
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      print(
        '✅ RESPONSE[${response.statusCode}] => ${response.requestOptions.uri}',
      );
      print('📥 DATA: ${response.data}');
    }
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      print(
        '❌ ERROR[${err.response?.statusCode}] => ${err.requestOptions.uri}',
      );
      print('💥 MESSAGE: ${err.message}');
      if (err.response?.data != null) {
        print('📥 ERROR DATA: ${err.response?.data}');
      }
    }
    super.onError(err, handler);
  }
}

/// Custom API exception
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final ApiExceptionType type;
  final Map<String, List<String>>? fieldErrors;

  ApiException({
    required this.message,
    this.statusCode,
    required this.type,
    this.fieldErrors,
  });

  /// Check if this is a validation error with field-specific errors
  bool get hasFieldErrors => fieldErrors != null && fieldErrors!.isNotEmpty;

  /// Get error message for a specific field
  String? getFieldError(String fieldName) {
    if (fieldErrors == null) return null;
    final errors = fieldErrors![fieldName];
    return errors?.isNotEmpty == true ? errors!.first : null;
  }

  /// Get all error messages as a list
  List<String> get allErrorMessages {
    if (fieldErrors == null || fieldErrors!.isEmpty) {
      return [message];
    }
    return fieldErrors!.values.expand((list) => list).toList();
  }

  @override
  String toString() {
    return 'ApiException(message: $message, statusCode: $statusCode, '
        'type: $type, fieldErrors: $fieldErrors)';
  }
}

/// Types of API exceptions
enum ApiExceptionType {
  network,
  timeout,
  badRequest,
  unauthorized,
  forbidden,
  notFound,
  server,
  cancel,
  unknown,
}
