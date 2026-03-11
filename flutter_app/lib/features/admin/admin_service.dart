import 'package:dio/dio.dart';
import '../../core/api_client.dart';

/// Admin API service wrapping all /api/admin/* endpoints.
class AdminService {
  final ApiClient _apiClient;

  AdminService(this._apiClient);

  Future<Map<String, dynamic>> getMetrics() async {
    final response = await _apiClient.dio.get('/admin/metrics');
    return response.data['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> listUsers({int page = 1, int limit = 20}) async {
    final response = await _apiClient.dio.get('/admin/users', queryParameters: {
      'page': page,
      'limit': limit,
    });
    return response.data['data'] as Map<String, dynamic>;
  }

  Future<List<dynamic>> getConfig() async {
    final response = await _apiClient.dio.get('/admin/config');
    return response.data['data']['config'] as List<dynamic>;
  }

  Future<Map<String, dynamic>> updateConfig(String key, String value) async {
    final response = await _apiClient.dio.put(
      '/admin/config/$key',
      data: {'value': value},
    );
    return response.data['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getAuditLog({int page = 1, int limit = 20}) async {
    final response = await _apiClient.dio.get('/admin/config/audit',
        queryParameters: {'page': page, 'limit': limit});
    return response.data['data'] as Map<String, dynamic>;
  }

  String parseError(DioException e) {
    final message = e.response?.data is Map
        ? e.response!.data['message'] as String?
        : null;
    return message ?? 'Request failed. Please try again.';
  }
}
