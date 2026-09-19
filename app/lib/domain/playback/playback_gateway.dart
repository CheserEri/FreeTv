import '../models/channel.dart';
import 'playback_state.dart';

/// 播放承载契约，对应《系统架构与服务契约 v0.1》第 3 节的 `PlaybackGateway`。
///
/// 实现方只允许导航到 [Channel.officialPageUrl] 指向的受信任官方域名，
/// 且不得向应用其他层暴露 Cookie、Token、DOM 内容、媒体地址或网络请求。
abstract interface class PlaybackGateway {
  /// 打开官方页面。目标地址不在白名单时不得发起任何请求。
  Future<void> open(Channel channel);

  /// 切换全屏。
  Future<void> setFullscreen(bool enabled);

  /// 播放状态流。同一时刻的取值可多次读取，订阅方负责取消订阅。
  Stream<PlaybackState> observeState();

  /// 释放承载资源。关闭后不应残留会话与后台请求。
  Future<void> close();
}