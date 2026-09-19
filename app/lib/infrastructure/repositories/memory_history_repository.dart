import '../../domain/models/watch_history.dart';
import '../../domain/repositories/history_repository.dart';

/// 进程内观看记录实现。Phase 1C 由 SQLite 实现替换。
class MemoryHistoryRepository implements HistoryRepository {
  final List<WatchHistory> _entries = <WatchHistory>[];

  @override
  Future<List<WatchHistory>> list({required int limit}) async =>
      _entries.take(limit).toList(growable: false);

  @override
  Future<void> recordOpened(String channelId, {String? programTitle}) async {
    _entries.removeWhere((entry) => entry.channelId == channelId);
    _entries.insert(
      0,
      WatchHistory(
        channelId: channelId,
        openedAt: DateTime.now(),
        lastProgramTitle: programTitle,
      ),
    );
  }

  @override
  Future<void> clear() async => _entries.clear();
}