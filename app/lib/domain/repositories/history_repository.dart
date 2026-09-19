import '../models/watch_history.dart';

/// 本机观看记录。只保存频道 ID 与打开时间，不保存流地址。
abstract interface class HistoryRepository {
  Future<List<WatchHistory>> list({required int limit});

  Future<void> recordOpened(String channelId, {String? programTitle});

  Future<void> clear();
}