import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../core/api_client.dart';

/// State and API calls for the notes feature.
class NotesProvider extends ChangeNotifier {
  final ApiClient _apiClient;

  bool _isLoading = false;
  String? _errorMessage;
  List<Map<String, dynamic>> _notes = [];
  int _total = 0;
  int _currentPage = 1;
  DateTime? _lastSyncedAt;
  static const int _pageSize = 20;

  NotesProvider(this._apiClient);

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<Map<String, dynamic>> get notes => _notes;
  int get total => _total;
  bool get hasMore => _notes.length < _total;
  DateTime? get lastSyncedAt => _lastSyncedAt;

  // ── Public API ───────────────────────────────────────────────────────────────

  /// Fetch page 1 of the user's notes (refresh).
  Future<void> fetchNotes() async {
    _setLoading(true);
    _errorMessage = null;
    _currentPage = 1;

    try {
      final response = await _apiClient.dio.get('/notes', queryParameters: {
        'page': 1,
        'limit': _pageSize,
        'sort': 'updated_at',
        'order': 'desc',
      });

      if (response.statusCode == 200) {
        final data = response.data['data'];
        _notes = List<Map<String, dynamic>>.from(data['notes'] ?? []);
        _total = data['pagination']?['total'] ?? 0;
      }
    } on DioException catch (e) {
      _errorMessage = _parseError(e);
    } finally {
      _setLoading(false);
    }
  }

  /// Load the next page and append to list.
  Future<void> fetchNextPage() async {
    if (_isLoading || !hasMore) return;
    _setLoading(true);
    _currentPage++;

    try {
      final response = await _apiClient.dio.get('/notes', queryParameters: {
        'page': _currentPage,
        'limit': _pageSize,
        'sort': 'updated_at',
        'order': 'desc',
      });

      if (response.statusCode == 200) {
        final data = response.data['data'];
        _notes.addAll(
          List<Map<String, dynamic>>.from(data['notes'] ?? []),
        );
        _total = data['pagination']?['total'] ?? 0;
      }
    } on DioException catch (e) {
      _errorMessage = _parseError(e);
      _currentPage--; // Roll back
    } finally {
      _setLoading(false);
    }
  }

  /// Create a new note. Returns the created note map or null on error.
  Future<Map<String, dynamic>?> createNote({
    required String title,
    String content = '',
    bool isPinned = false,
    int? categoryId,
    String? priority,
    List<int>? tagIds,
  }) async {
    _errorMessage = null;

    try {
      final payload = <String, dynamic>{
        'title': title,
        'content': content,
        'is_pinned': isPinned,
      };
      if (categoryId != null) payload['category_id'] = categoryId;
      if (priority != null) payload['priority'] = priority;
      if (tagIds != null && tagIds.isNotEmpty) payload['tag_ids'] = tagIds;

      final response = await _apiClient.dio.post('/notes', data: payload);

      if (response.statusCode == 201) {
        final note = Map<String, dynamic>.from(response.data['data']);
        _notes.insert(0, note);
        _total++;
        notifyListeners();
        return note;
      }
    } on DioException catch (e) {
      _errorMessage = _parseError(e);
      notifyListeners();
    }
    return null;
  }

  /// Update an existing note. Returns the updated note or null on error.
  Future<Map<String, dynamic>?> updateNote(
    int id, {
    String? title,
    String? content,
    bool? isPinned,
    int? categoryId,
    String? priority,
    List<int>? tagIds,
  }) async {
    _errorMessage = null;

    try {
      final payload = <String, dynamic>{};
      if (title != null) payload['title'] = title;
      if (content != null) payload['content'] = content;
      if (isPinned != null) payload['is_pinned'] = isPinned;
      if (categoryId != null) payload['category_id'] = categoryId;
      if (priority != null) payload['priority'] = priority;
      if (tagIds != null) payload['tag_ids'] = tagIds;

      final response = await _apiClient.dio.patch('/notes/$id', data: payload);

      if (response.statusCode == 200) {
        final updated = Map<String, dynamic>.from(response.data['data']);
        final idx = _notes.indexWhere((n) => n['id'] == id);
        if (idx != -1) {
          _notes[idx] = updated;
          notifyListeners();
        }
        return updated;
      }
    } on DioException catch (e) {
      _errorMessage = _parseError(e);
      notifyListeners();
    }
    return null;
  }

  /// Delete a note by ID.
  Future<bool> deleteNote(int id) async {
    _errorMessage = null;

    try {
      final response = await _apiClient.dio.delete('/notes/$id');
      if (response.statusCode == 200) {
        _notes.removeWhere((n) => n['id'] == id);
        _total = (_total - 1).clamp(0, _total);
        notifyListeners();
        return true;
      }
    } on DioException catch (e) {
      _errorMessage = _parseError(e);
      notifyListeners();
    }
    return false;
  }

  // ── Sync helpers ─────────────────────────────────────────────────────────────

  /// Set the timestamp recorded from the server after a successful sync.
  void setLastSyncedAt(DateTime time) {
    _lastSyncedAt = time;
  }

  /// Merge a sync delta into local state.
  /// Updated notes are upserted by id; deleted_ids are removed.
  void applyDelta(
      List<Map<String, dynamic>> updated, List<int> deletedIds) {
    // Remove deleted notes
    if (deletedIds.isNotEmpty) {
      _notes.removeWhere((n) => deletedIds.contains(n['id']));
      _total = (_total - deletedIds.length).clamp(0, _total);
    }
    // Upsert updated notes
    for (final updatedNote in updated) {
      final idx = _notes.indexWhere((n) => n['id'] == updatedNote['id']);
      if (idx != -1) {
        _notes[idx] = updatedNote;
      } else {
        _notes.insert(0, updatedNote);
        _total++;
      }
    }
    if (updated.isNotEmpty || deletedIds.isNotEmpty) notifyListeners();
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

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
