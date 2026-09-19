/// 本机收藏。只保存频道 ID。
abstract interface class FavoriteRepository {
  Future<List<String>> list();

  Future<void> set(String channelId, {required bool favorite});
}