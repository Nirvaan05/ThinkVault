import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../core/api_client.dart';

/// Authentication state and API calls.
class AuthProvider extends ChangeNotifier {
  final ApiClient _apiClient;

  bool _isLoading = false;
  bool _isAuthenticated = false;
  bool _requiresOtp = false;
  String? _errorMessage;
  Map<String, dynamic>? _user;

  AuthProvider(this._apiClient);

  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  bool get requiresOtp => _requiresOtp;
  bool get isAdmin => _user?['role'] == 'admin';
  String? get errorMessage => _errorMessage;
  Map<String, dynamic>? get user => _user;

  /// Register a new user.
  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final response = await _apiClient.dio.post('/auth/register', data: {
        'name': name,
        'email': email,
        'password': password,
      });

      if (response.statusCode == 201) {
        _setLoading(false);
        return true;
      }

      _errorMessage = response.data['message'] ?? 'Registration failed';
      _setLoading(false);
      return false;
    } on DioException catch (e) {
      _errorMessage = _parseError(e);
      _setLoading(false);
      return false;
    }
  }

  /// Log in with email and password.
  /// If the account has OTP enabled, [requiresOtp] will be set to true.
  /// Call [loginWithOtp] next to complete the flow.
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _errorMessage = null;
    _requiresOtp = false;

    try {
      final response = await _apiClient.dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });

      if (response.statusCode == 200) {
        final data = response.data['data'];

        if (data['requires_otp'] == true) {
          _requiresOtp = true;
          _setLoading(false);
          return false; // Not authenticated yet — OTP step needed
        }

        _user = data['user'];
        await _apiClient.saveToken(data['token']);
        _isAuthenticated = true;
        _setLoading(false);
        return true;
      }

      _errorMessage = response.data['message'] ?? 'Login failed';
      _setLoading(false);
      return false;
    } on DioException catch (e) {
      _errorMessage = _parseError(e);
      _setLoading(false);
      return false;
    }
  }

  /// Complete login when OTP is required.
  /// Call after [login] returns false with [requiresOtp] == true.
  Future<bool> loginWithOtp({
    required String email,
    required String password,
    required String otpToken,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final response = await _apiClient.dio.post('/auth/login', data: {
        'email': email,
        'password': password,
        'otp_token': otpToken,
      });

      if (response.statusCode == 200) {
        final data = response.data['data'];
        _user = data['user'];
        await _apiClient.saveToken(data['token']);
        _isAuthenticated = true;
        _requiresOtp = false;
        _setLoading(false);
        return true;
      }

      _errorMessage = response.data['message'] ?? 'OTP verification failed';
      _setLoading(false);
      return false;
    } on DioException catch (e) {
      _errorMessage = _parseError(e);
      _setLoading(false);
      return false;
    }
  }

  /// Log out, revoke the server-side token, and clear local storage.
  Future<void> logout() async {
    try {
      await _apiClient.dio.post('/auth/logout');
    } catch (_) {
      // Best-effort — clear locally even if request fails
    }
    await _apiClient.clearToken();
    _isAuthenticated = false;
    _requiresOtp = false;
    _user = null;
    notifyListeners();
  }

  /// Check if the user is already logged in (token present in storage).
  Future<void> checkAuthStatus() async {
    final hasToken = await _apiClient.hasToken();
    _isAuthenticated = hasToken;
    notifyListeners();
  }

  // ── OTP Methods ─────────────────────────────────────────────────────────────

  /// Request OTP setup — returns the QR code data URI and otpauth URL.
  Future<Map<String, dynamic>?> setupOtp() async {
    try {
      final response = await _apiClient.dio.post('/auth/otp/setup');
      if (response.statusCode == 200) {
        return response.data['data'] as Map<String, dynamic>;
      }
      return null;
    } on DioException catch (e) {
      _errorMessage = _parseError(e);
      notifyListeners();
      return null;
    }
  }

  /// Verify a 6-digit TOTP code and enable OTP for the account.
  Future<bool> verifyOtp(String token) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      final response = await _apiClient.dio.post('/auth/otp/verify', data: {
        'token': token,
      });
      _setLoading(false);
      return response.statusCode == 200;
    } on DioException catch (e) {
      _errorMessage = _parseError(e);
      _setLoading(false);
      return false;
    }
  }

  /// Disable OTP by confirming the user's password.
  Future<bool> disableOtp(String password) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      final response = await _apiClient.dio.post('/auth/otp/disable', data: {
        'password': password,
      });
      _setLoading(false);
      return response.statusCode == 200;
    } on DioException catch (e) {
      _errorMessage = _parseError(e);
      _setLoading(false);
      return false;
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  /// Extract a readable error message from a DioException.
  /// Surfaces lockout (423) messages distinctly.
  String _parseError(DioException e) {
    final statusCode = e.response?.statusCode;
    final message = e.response?.data is Map
        ? e.response!.data['message'] as String?
        : null;

    if (statusCode == 423) {
      return message ?? 'Account is temporarily locked. Please try again later.';
    }
    return message ?? 'Network error. Please check your connection.';
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
