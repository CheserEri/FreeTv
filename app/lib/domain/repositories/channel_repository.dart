import '../models/channel.dart';

/// 频道目录。UI 只依赖此契约，不接触官方页面或接口细节。
abstract interface class ChannelRepository {
  Future<List<Channel>> list({ChannelCategory? category});

  Future<List<Channel>> search(String query);

  Future<Channel?> getById(String id);
}