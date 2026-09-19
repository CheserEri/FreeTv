import 'package:flutter/foundation.dart';

/// 本机观看记录。只保存频道 ID 与打开时间，不保存流地址。
@immutable
class WatchHistory {
  const WatchHistory({
    required this.channelId,
    required this.openedAt,
    this.lastProgramTitle,
  });

  final String channelId;
  final DateTime openedAt;
  final String? lastProgramTitle;
}