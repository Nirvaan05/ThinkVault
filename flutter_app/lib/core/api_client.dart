import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_config.dart';

/// Centralized HTTP client for ThinkVault API calls.
class ApiClient {
  late final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  ApiClient() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: Duration(milliseconds: ApiConfig.timeoutMs),
      receiveTimeout: Duration(milliseconds: ApiConfig.timeoutMs),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // Add auth token interceptor
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: ApiConfig.tokenKey);
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) {
        // Handle 401 globally (e.g., redirect to login)
        handler.next(error);
      },
    ));
  }

  Dio get dio => _dio;

  /// Save auth token securely.
  Future<void> saveToken(String token) async {
    await _storage.write(key: ApiConfig.tokenKey, value: token);
  }

  /// Clear auth token (logout).
  Future<void> clearToken() async {
    await _storage.delete(key: ApiConfig.tokenKey);
  }

  /// Check if token exists.
  Future<bool> hasToken() async {
    final token = await _storage.read(key: ApiConfig.tokenKey);
    return token != null;
  }
}
