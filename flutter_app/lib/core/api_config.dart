/// ThinkVault API client configuration.
class ApiConfig {
  /// Base URL for the backend API.
  static const String baseUrl = 'http://localhost:3000/api';

  /// Request timeout in milliseconds.
  static const int timeoutMs = 30000;

  /// Storage key for the auth token.
  static const String tokenKey = 'auth_token';
}
