import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';
import 'package:webview_win_floating/webview_win_floating.dart';

import '../../domain/models/channel.dart';
import '../../domain/playback/playback_gateway.dart';
import '../../domain/playback/playback_state.dart';
import '../official_url_policy.dart';

/// 基于 Windows WebView2 的官方页面承载实现。
///
/// 边界（对应《WebView POC 白名单与隐私测试清单》）：
/// - 顶层导航只允许白名单内的官方 HTTPS 地址；
/// - 不注入 JS、不添加 JS bridge、不读取 Cookie 与页面内容；
/// - 暴露给上层的只有 [PlaybackState]、触发过拦截的主机名与全屏标记，
///   因此其他层拿不到认证信息、DOM 内容或媒体地址。
///
/// W-2 已知边界：`webview_win_floating` 3.0.3 在 `NavigationStarting` 里把
/// 重定向（`IsRedirected == TRUE`）与带 `Content-Type` 的 POST 导航判为
/// 「非用户发起」而直接放行，不询问 Dart 侧
/// （`windows/my_webview.cpp:206-237`）。因此这类跳转无法被**事前**拦截，
/// 只能靠 [PlaybackGateway] 在 `onPageStarted` 上做**事后检测 + 退回官方入口**。
///
/// W-3 已知边界：插件未注册 `WebResourceRequested`，子资源请求完全不经过本层。
/// 真机观测到一次页面加载涉及 17 个主机，白名单无法约束子资源；
/// 该风险由「不导出 Cookie / Token / DOM / 媒体地址」这一数据边界约束兜底。
class WinWebPlaybackGateway implements PlaybackGateway {
  WinWebPlaybackGateway() {
    _controller = WinWebViewController(
      params: WindowsWebViewControllerCreationParams(
        userDataFolder: _userDataFolder(),
        profileName: _profileName,
      ),
      // 官方电视页不需要摄像头、麦克风、定位或通知，全部拒绝。
      onPermissionRequest: (request) => request.deny(),
    );
  }

  /// 加载超时。超时后进入可重试的失败态，避免长时间停留在空白加载中。
  static const loadTimeout = Duration(seconds: 25);

  /// 单次打开允许的「退回官方入口」次数上限。
  ///
  /// 退回本身是一次新的导航，若官方页面每次加载都跳出去，退回会变成死循环；
  /// 超过上限就停手并进入受限态，把控制权交回用户。
  static const _maxReturnAttempts = 2;

  static const _profileName = 'ytv-official';

  late final WinWebViewController _controller;

  final StreamController<PlaybackState> _states =
      StreamController<PlaybackState>.broadcast();

  /// 全屏标记。官方页面内触发的全屏也会同步到这里。
  final ValueNotifier<bool> fullscreen = ValueNotifier<bool>(false);

  final Set<String> _blockedHosts = <String>{};

  PlaybackState _state = const PlaybackIdle();
  Timer? _timeout;
  String? _openedChannelId;
  String? _officialEntry;
  int _returnAttempts = 0;
  bool _closed = false;

  /// 被拦截过的主机名（不含路径与查询参数），用于白名单审计。
  Set<String> get blockedHosts => Set<String>.unmodifiable(_blockedHosts);

  @override
  Stream<PlaybackState> observeState() async* {
    yield _state;
    yield* _states.stream;
  }

  @override
  Future<void> open(Channel channel) async {
    if (_closed) return;

    final decision = OfficialUrlPolicy.check(channel.officialPageUrl);
    if (!decision.allowed) {
      // 白名单拒绝：不发起任何请求。
      _emit(
        PlaybackFailed(
          channelId: channel.id,
          retryable: false,
          message: '该频道地址不在官方白名单内，已阻止打开',
        ),
      );
      return;
    }

    await _controller.setVisibility(false);
    await _controller.setJavaScriptMode(JavaScriptMode.unrestricted);
    await _controller.setNavigationDelegate(
      WinNavigationDelegate(
        onNavigationRequest: _onNavigationRequest,
        onPageStarted: _onPageStarted,
        onPageFinished: _onPageFinished,
        // 插件缺陷规避：notifyOnHttpError_ 以 onPageFinished 判空、
        // 却调用 onHttpError，二者只设其一会在发生 HTTP 错误时抛异常。
        // 这里只做占位，不用它改写状态，以免子资源 404 被误判为主页面失败。
        onHttpError: (_) {},
        onWebResourceError: _onWebResourceError,
        onFullScreenChanged: (isFullScreen) => fullscreen.value = isFullScreen,
      ),
    );

    _openedChannelId = channel.id;
    _officialEntry = channel.officialPageUrl;
    _returnAttempts = 0;
    _emit(PlaybackLoading(channel.id));
    _restartTimeout(channel.id);
    await _controller.loadRequest(Uri.parse(channel.officialPageUrl));
  }

  @override
  Future<void> setFullscreen(bool enabled) async {
    if (_closed) return;
    fullscreen.value = enabled;
    _controller.setFullScreen(enabled);
  }

  @override
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    _timeout?.cancel();
    _timeout = null;
    await _states.close();
    fullscreen.dispose();
    // 释放 WebView2 实例，避免残留会话与后台请求。
    await _controller.dispose();
    _state = const PlaybackIdle();
  }

  /// 渲染官方页面表面。控制器不对外暴露，只有本文件能构造它。
  Widget buildSurface() => WinWebViewWidget(controller: _controller);

  Future<NavigationDecision> _onNavigationRequest(
    NavigationRequest request,
  ) async {
    final decision = OfficialUrlPolicy.check(request.url);
    if (decision.allowed) return NavigationDecision.navigate;

    if (decision.host != null) _blockedHosts.add(decision.host!);
    return NavigationDecision.prevent;
  }

  void _onPageStarted(String url) {
    if (_closed || _openedChannelId == null) return;

    final decision = OfficialUrlPolicy.check(url);
    if (!decision.allowed && _isNetworkNavigation(url)) {
      _handleOffWhitelistNavigation(decision);
      return;
    }

    if (_state is PlaybackPlaying) return;
    _emit(PlaybackLoading(_openedChannelId!));
  }

  /// W-2 事后检测：官方页面跳出了白名单，记录证据并退回官方入口。
  ///
  /// 走到这里说明插件把这次导航判成了「非用户发起」（重定向或 POST）而直接放行，
  /// `onNavigationRequest` 没有被调用，事前拦截已经错过。
  void _handleOffWhitelistNavigation(UrlPolicyDecision decision) {
    final channelId = _openedChannelId!;
    if (decision.host != null) _blockedHosts.add(decision.host!);

    if (_returnAttempts >= _maxReturnAttempts) {
      _timeout?.cancel();
      _controller.setVisibility(false);
      _emit(
        PlaybackRestricted(channelId, '官方页面反复跳转到非白名单地址，已停止加载'),
      );
      return;
    }

    final entry = _officialEntry;
    if (entry == null) return;
    _returnAttempts++;
    _restartTimeout(channelId);
    unawaited(_controller.loadRequest(Uri.parse(entry)));
  }

  /// 只对真实的网络导航做事后检测。
  ///
  /// WebView2 初始化与页面内部会产生 `about:blank` 这类非网络导航，
  /// 它们不是「跳出白名单」的证据；把它们算作越界会让正常播放被打断。
  /// 重定向与 POST 这类绕过路径必然走 http(s)，所以这个过滤不会漏掉真正的越界。
  static bool _isNetworkNavigation(String url) {
    final lower = url.toLowerCase();
    return lower.startsWith('http://') || lower.startsWith('https://');
  }

  void _onPageFinished(String url) {
    if (_closed) return;
    final channelId = _openedChannelId;
    if (channelId == null) return;
    // 只有白名单内的主页面才算加载成功。
    if (!OfficialUrlPolicy.check(url).allowed) return;
    _timeout?.cancel();
    _emit(PlaybackPlaying(channelId));
    _controller.setVisibility(true);
  }

  void _onWebResourceError(WebResourceError error) {
    // 仅在主框架失败时报错，避免子资源失败造成误报；
    // 实现未标注主框架时交由加载超时兜底。
    if (error.isForMainFrame != true) return;
    final channelId = _openedChannelId;
    if (channelId == null) return;
    _timeout?.cancel();
    _controller.setVisibility(false);
    _emit(
      PlaybackFailed(
        channelId: channelId,
        retryable: true,
        message: '官方页面加载失败，请检查网络后重试',
      ),
    );
  }

  void _restartTimeout(String channelId) {
    _timeout?.cancel();
    _timeout = Timer(loadTimeout, () {
      if (_closed || _state is PlaybackPlaying) return;
      _emit(
        PlaybackFailed(
          channelId: channelId,
          retryable: true,
          message: '官方页面加载超时，请检查网络后重试',
        ),
      );
    });
  }

  void _emit(PlaybackState state) {
    if (_closed) return;
    _state = state;
    if (!_states.isClosed) _states.add(state);
  }

  /// 用户数据目录不放在可执行文件同级（安装目录可能只读）。
  static String? _userDataFolder() {
    final localAppData = Platform.environment['LOCALAPPDATA'];
    if (localAppData == null || localAppData.isEmpty) return null;
    return '$localAppData${Platform.pathSeparator}YTV'
        '${Platform.pathSeparator}WebView2';
  }
}