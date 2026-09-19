import 'package:flutter/foundation.dart';

/// 播放状态，对应《系统架构与服务契约 v0.1》第 2 节的 `PlaybackState`。
///
/// 每个状态只承载 YTV 自己的频道 ID 与面向用户的文案，不含 Cookie、Token、
/// DOM 内容、网络请求或媒体地址。因此“播放中”只能表示官方页面已就绪，
/// 而不代表已确认画面正在播放——YTV 不读取页面状态来判断这一点。
@immutable
sealed class PlaybackState {
  const PlaybackState();

  /// 该状态对应的频道 ID；尚未打开任何频道时为 null。
  String? get channelId;
}

/// 尚未打开官方页面。
final class PlaybackIdle extends PlaybackState {
  const PlaybackIdle();

  @override
  String? get channelId => null;
}

/// 正在加载官方页面。
final class PlaybackLoading extends PlaybackState {
  const PlaybackLoading(this.channelId);

  @override
  final String channelId;
}

/// 官方页面已就绪，后续播放由官方页面自行完成。
final class PlaybackPlaying extends PlaybackState {
  const PlaybackPlaying(this.channelId);

  @override
  final String channelId;
}

/// 需要用户在官方页面内自行完成登录或授权。
final class PlaybackNeedsOfficialLogin extends PlaybackState {
  const PlaybackNeedsOfficialLogin(this.channelId);

  @override
  final String channelId;
}

/// 官方页面提示内容受限（会员或地区限制）。
final class PlaybackRestricted extends PlaybackState {
  const PlaybackRestricted(this.channelId, this.message);

  @override
  final String channelId;

  /// 面向用户的受限说明，不包含地址与参数。
  final String message;
}

/// 加载失败。
final class PlaybackFailed extends PlaybackState {
  const PlaybackFailed({
    required this.channelId,
    required this.retryable,
    required this.message,
  });

  @override
  final String channelId;

  /// 是否可重试；白名单拒绝等安全类失败为 false。
  final bool retryable;

  /// 面向用户的失败说明，不包含地址与参数。
  final String message;
}