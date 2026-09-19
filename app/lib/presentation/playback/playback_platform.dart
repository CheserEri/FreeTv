/// 平台承载接缝：把 WebView 插件的平台差异限制在这里。
///
/// Web 构建不能引入 WebView2 插件（其实现依赖 `dart:io`），
/// 因此按库可用性选择实现，接口保持一致：
/// - `createPlaybackGateway()`：不支持内嵌官方页面时返回 null；
/// - `buildPlaybackSurface()`：渲染官方页面表面；
/// - `blockedHostsOf()`：审计被拦截的主机名；
/// - `fullscreenOf()`：全屏标记。
library;

export 'playback_platform_stub.dart'
    if (dart.library.io) 'playback_platform_io.dart';