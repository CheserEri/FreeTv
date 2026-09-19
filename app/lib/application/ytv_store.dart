import 'package:flutter/foundation.dart';

import '../domain/models/channel.dart';
import '../domain/models/watch_history.dart';
import '../domain/repositories/channel_repository.dart';
import '../domain/repositories/favorite_repository.dart';
import '../domain/repositories/history_repository.dart';

/// 本机状态：频道目录、收藏与观看历史。
///
/// 页面只通过本类读取与修改本机数据，不接触仓储实现细节。
class YtvStore extends ChangeNotifier {
  YtvStore({
    required this.channels,
    required this.favorites,
    required this.history,
  });

  static const recentLimit = 10;

  final ChannelRepository channels;
  final FavoriteRepository favorites;
  final HistoryRepository history;

  List<String> _favoriteIds = const <String>[];
  List<WatchHistory> _recent = const <WatchHistory>[];
  bool _loaded = false;

  bool get isLoaded => _loaded;
  List<String> get favoriteIds => _favoriteIds;
  List<WatchHistory> get recent => _recent;

  bool isFavorite(String channelId) => _favoriteIds.contains(channelId);

  Future<void> load() async {
    _favoriteIds = await favorites.list();
    _recent = await history.list(limit: recentLimit);
    _loaded = true;
    notifyListeners();
  }

  Future<void> toggleFavorite(String channelId) async {
    await favorites.set(channelId, favorite: !isFavorite(channelId));
    _favoriteIds = await favorites.list();
    notifyListeners();
  }

  Future<void> recordOpened(Channel channel, {String? programTitle}) async {
    await history.recordOpened(channel.id, programTitle: programTitle);
    _recent = await history.list(limit: recentLimit);
    notifyListeners();
  }

  Future<void> clearHistory() async {
    await history.clear();
    _recent = const <WatchHistory>[];
    notifyListeners();
  }
}