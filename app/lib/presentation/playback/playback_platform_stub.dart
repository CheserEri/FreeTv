import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../../domain/playback/playback_gateway.dart';

/// Web 端不提供内嵌官方页面：既没有 WebView2，也不做请求转发或代理。
PlaybackGateway? createPlaybackGateway() => null;

Widget buildPlaybackSurface(PlaybackGateway gateway) => const SizedBox.shrink();

Set<String> blockedHostsOf(PlaybackGateway gateway) => const <String>{};

ValueListenable<bool>? fullscreenOf(PlaybackGateway gateway) => null;