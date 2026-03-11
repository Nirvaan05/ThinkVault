import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../core/api_client.dart';
import 'notes_provider.dart';

/// Handles cross-device note synchronisation via the backend delta endpoint.
///
/// Conflict resolution: last-write-wins by [updated_at].
/// The server's [updated_at] timestamp is authoritative.
///
/// Call [syncDelta] on app resume to pull changes made on other devices.
class SyncService {
  final ApiClient _apiClient;
  final NotesProvider _notesProvider;

  SyncService(this._apiClient, this._notesProvider);

  /// Fetch notes updated since [_notesProvider.lastSyncedAt] and merge them.
  Future<void> syncDelta() async {
    final since = _notesProvider.lastSyncedAt;
    final sinceParam = since?.toUtc().toIso8601String() ??
        DateTime.fromMillisecondsSinceEpoch(0).toIso8601String();

    try {
      final response = await _apiClient.dio.get(
        '/sync/delta',
        queryParameters: {'since': sinceParam},
      );

      if (response.statusCode == 200) {
        final data = response.data['data'] as Map<String, dynamic>;
        final updated = List<Map<String, dynamic>>.from(data['updated'] ?? []);
        final deletedIds = List<int>.from(
          (data['deleted_ids'] as List?)?.map((e) => e as int) ?? [],
        );
        final serverTime = data['server_time'] as String?;

        _notesProvider.applyDelta(updated, deletedIds);

        if (serverTime != null) {
          _notesProvider.setLastSyncedAt(DateTime.parse(serverTime));
        }

        if (kDebugMode) {
          debugPrint(
            '[SyncService] Delta synced: ${updated.length} updated, '
            '${deletedIds.length} deleted',
          );
        }
      }
    } on DioException catch (e) {
      if (kDebugMode) {
        debugPrint('[SyncService] Sync error: ${e.message}');
      }
      // Sync failures are non-fatal — user still has the cached data
    }
  }
}
