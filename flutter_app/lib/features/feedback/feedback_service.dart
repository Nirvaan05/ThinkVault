import 'package:dio/dio.dart';
import '../../core/api_client.dart';

/// Service for all /api/feedback endpoints.
class FeedbackService {
  final ApiClient _apiClient;

  FeedbackService(this._apiClient);

  /// Submit feedback or a bug report.
  Future<Map<String, dynamic>> submit({
    required String type,   // 'feedback' | 'bug'
    required String subject,
    required String body,
  }) async {
    final response = await _apiClient.dio.post('/feedback', data: {
      'type': type,
      'subject': subject,
      'body': body,
    });
    return response.data['data'] as Map<String, dynamic>;
  }

  /// Admin: list all entries with optional filters.
  Future<Map<String, dynamic>> list({
    String? type,
    String? status,
    int page = 1,
    int limit = 30,
  }) async {
    final response = await _apiClient.dio.get('/feedback', queryParameters: {
      if (type != null) 'type': type,
      if (status != null) 'status': status,
      'page': page,
      'limit': limit,
    });
    return response.data['data'] as Map<String, dynamic>;
  }

  /// Admin: get a single entry by id.
  Future<Map<String, dynamic>> getById(int id) async {
    final response = await _apiClient.dio.get('/feedback/$id');
    return response.data['data'] as Map<String, dynamic>;
  }

  /// Admin: update the status of an entry.
  Future<Map<String, dynamic>> updateStatus(int id, String status) async {
    final response = await _apiClient.dio.patch(
      '/feedback/$id/status',
      data: {'status': status},
    );
    return response.data['data'] as Map<String, dynamic>;
  }

  String parseError(DioException e) {
    final message = e.response?.data is Map
        ? e.response!.data['message'] as String?
        : null;
    return message ?? 'Request failed. Please try again.';
  }
}
