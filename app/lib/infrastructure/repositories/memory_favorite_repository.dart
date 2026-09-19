import '../../domain/repositories/favorite_repository.dart';

/// 进程内收藏实现。Phase 1C 由 SQLite 实现替换。
class MemoryFavoriteRepository implements FavoriteRepository {
  final Set<String> _ids = <String>{};

  @override
  Future<List<String>> list() async => _ids.toList(growable: false);

  @override
  Future<void> set(String channelId, {required bool favorite}) async {
    if (favorite) {
      _ids.add(channelId);
    } else {
      _ids.remove(channelId);
    }
  }
}