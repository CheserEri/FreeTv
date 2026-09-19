import 'package:flutter/foundation.dart';

enum ChannelCategory { cctv, satellite, other }

enum ChannelAvailability { unknown, available, restricted }

@immutable
class Channel {
  const Channel({
    required this.id,
    required this.name,
    required this.category,
    required this.officialPageUrl,
    this.logoAsset,
    this.availability = ChannelAvailability.unknown,
  });

  /// YTV 稳定 ID，例如 `cctv-1`。
  final String id;
  final String name;
  final ChannelCategory category;

  /// 官方公开页面地址，不是媒体地址。播放层只允许导航到白名单官方域名。
  final String officialPageUrl;

  final String? logoAsset;
  final ChannelAvailability availability;
}