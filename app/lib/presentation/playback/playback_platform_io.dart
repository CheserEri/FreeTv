import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../../domain/playback/playback_gateway.dart';
import '../../infrastructure/playback/win_web_playback_gateway.dart';

/// 内嵌官方页面只在 Windows 上启用；其他平台由播放页显示官方地址提示。
///
/// `flutter_test` 环境没有平台通道，创建 WebView2 会抛
/// `MissingPluginException`，因此测试下同样不创建实例。
PlaybackGateway? createPlaybackGateway() {
  if (!Platform.isWindows) return null;
  if (Platform.environment['FLUTTER_TEST'] == 'true') return null;
  return WinWebPlaybackGateway();
}

Widget buildPlaybackSurface(PlaybackGateway gateway) =>
    gateway is WinWebPlaybackGateway
        ? gateway.buildSurface()
        : const SizedBox.shrink();

Set<String> blockedHostsOf(PlaybackGateway gateway) =>
    gateway is WinWebPlaybackGateway ? gateway.blockedHosts : const <String>{};

ValueListenable<bool>? fullscreenOf(PlaybackGateway gateway) =>
    gateway is WinWebPlaybackGateway ? gateway.fullscreen : null;