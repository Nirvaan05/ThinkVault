import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../core/api_client.dart';

/// Manages attachment list state and API calls for a single note.
class AttachmentsProvider extends ChangeNotifier {
  final ApiClient _apiClient;

  bool _isLoading = false;
  String? _errorMessage;
  List<Map<String, dynamic>> _attachments = [];
  // ignore: unused_field
  int? _currentNoteId;

  AttachmentsProvider(this._apiClient);

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<Map<String, dynamic>> get attachments => _attachments;

  // ── Public API ──────────────────────────────────────────────────────────────

  /// Load attachments for [noteId].
  Future<void> loadAttachments(int noteId) async {
    _currentNoteId = noteId;
    _setLoading(true);
    _errorMessage = null;

    try {
      final response = await _apiClient.dio.get('/notes/$noteId/attachments');
      if (response.statusCode == 200) {
        _attachments =
            List<Map<String, dynamic>>.from(response.data['data'] ?? []);
      }
    } on DioException catch (e) {
      _errorMessage = _parseError(e);
    } finally {
      _setLoading(false);
    }
  }

  /// Upload a file to the current note. Uses multipart form data.
  Future<bool> uploadAttachment(int noteId, String filePath) async {
    _errorMessage = null;
    _setLoading(true);

    try {
      final fileName = filePath.split(Platform.pathSeparator).last;
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath, filename: fileName),
      });

      final response = await _apiClient.dio.post(
        '/notes/$noteId/attachments',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );

      if (response.statusCode == 201) {
        final attachment =
            Map<String, dynamic>.from(response.data['data'] ?? {});
        _attachments.add(attachment);
        notifyListeners();
        return true;
      }
    } on DioException catch (e) {
      _errorMessage = _parseError(e);
      notifyListeners();
    } finally {
      _setLoading(false);
    }
    return false;
  }

  /// Delete an attachment by ID.
  Future<bool> deleteAttachment(int attachmentId) async {
    _errorMessage = null;

    try {
      final response =
          await _apiClient.dio.delete('/attachments/$attachmentId');
      if (response.statusCode == 200) {
        _attachments.removeWhere((a) => a['id'] == attachmentId);
        notifyListeners();
        return true;
      }
    } on DioException catch (e) {
      _errorMessage = _parseError(e);
      notifyListeners();
    }
    return false;
  }

  /// Returns the download URL for an attachment (used by open_filex / in-app download).
  String downloadUrl(int attachmentId) {
    final baseUrl = _apiClient.dio.options.baseUrl.replaceAll(RegExp(r'/$'), '');
    return '$baseUrl/attachments/$attachmentId/download';
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  String _parseError(DioException e) {
    final message = e.response?.data is Map
        ? e.response!.data['message'] as String?
        : null;
    return message ?? 'Network error. Please check your connection.';
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
