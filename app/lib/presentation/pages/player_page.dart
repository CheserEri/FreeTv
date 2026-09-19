import 'dart:async';

import 'package:flutter/material.dart';

import '../../application/ytv_scope.dart';
import '../../domain/models/channel.dart';
import '../../domain/playback/playback_gateway.dart';
import '../../domain/playback/playback_state.dart';
import '../playback/playback_platform.dart';
import '../routes.dart';
import '../theme/ytv_tokens.dart';

/// 打开频道播放页，并记录本机观看历史。
void openPlayer(BuildContext context, Channel channel) {
  Navigator.of(context).pushNamed(Routes.player, arguments: channel);
}

/// 播放页：由官方页面在 WebView 内完成播放，YTV 不接管媒体链路。
///
/// 页面只消费 [PlaybackState]，不接触网页内容、Cookie 或媒体地址；
/// 关闭页面即释放 WebView。
class PlayerPage extends StatefulWidget {
  const PlayerPage({super.key, required this.channel});

  final Channel channel;

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> {
  PlaybackGateway? _gateway;
  StreamSubscription<PlaybackState>? _subscription;
  PlaybackState _state = const PlaybackIdle();
  bool _recorded = false;

  @override
  void initState() {
    super.initState();
    final gateway = createPlaybackGateway();
    _gateway = gateway;
    _subscription = gateway?.observeState().listen((state) {
      if (mounted) setState(() => _state = state);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_recorded) return;
    _recorded = true;
    YtvScope.of(context).recordOpened(widget.channel);
    _gateway?.open(widget.channel);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    // 关闭播放页即释放承载资源。
    _gateway?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(
              channel: widget.channel,
              gateway: _gateway,
              onExit: () => Navigator.of(context).maybePop(),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  YtvSpacing.lg,
                  0,
                  YtvSpacing.lg,
                  YtvSpacing.lg,
                ),
                child: _buildPlaybackArea(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaybackArea() {
    final gateway = _gateway;
    if (gateway == null) {
      return _NoticePane(
        icon: Icons.open_in_new,
        title: '当前平台未启用内嵌官方页面',
        detail: '请在官方电视页观看。YTV 不代理、不转发任何媒体内容。',
        officialAddress: widget.channel.officialPageUrl,
      );
    }

    final blocked = blockedHostsOf(gateway);
    return Column(
      children: [
        Expanded(
          child: ColoredBox(
            color: YtvColors.canvas,
            child: Stack(
              children: [
                Positioned.fill(child: buildPlaybackSurface(gateway)),
                // 官方页面未就绪时隐藏 WebView，用本层状态视图代替空白页。
                if (_state is! PlaybackPlaying)
                  Positioned.fill(child: _buildStatusPane(gateway)),
              ],
            ),
          ),
        ),
        if (blocked.isNotEmpty) _BlockedHostsStrip(hosts: blocked),
      ],
    );
  }

  Widget _buildStatusPane(PlaybackGateway gateway) {
    switch (_state) {
      case PlaybackIdle():
        return const _NoticePane(
          icon: Icons.hourglass_empty,
          title: '正在准备官方页面',
          detail: 'YTV 只在官方页面内打开频道，不读取网页内容。',
        );
      case PlaybackLoading():
        return const _NoticePane(
          icon: Icons.sync,
          title: '正在加载官方页面',
          detail: '首次加载可能需要几秒。',
          busy: true,
        );
      case PlaybackNeedsOfficialLogin():
        return const _NoticePane(
          icon: Icons.lock_outline,
          title: '需要在官方页面登录',
          detail: '请在官方页面内自行完成登录，YTV 不读取、不代替登录。',
        );
      case PlaybackRestricted(:final message):
        return _NoticePane(
          icon: Icons.block,
          title: '内容受限',
          detail: message,
        );
      case PlaybackFailed(:final message, :final retryable):
        return _NoticePane(
          icon: Icons.error_outline,
          title: '无法打开官方页面',
          detail: message,
          onRetry: retryable ? () => gateway.open(widget.channel) : null,
        );
      case PlaybackPlaying():
        return const SizedBox.shrink();
    }
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.channel,
    required this.gateway,
    required this.onExit,
  });

  final Channel channel;
  final PlaybackGateway? gateway;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final listenable = gateway == null ? null : fullscreenOf(gateway!);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: YtvSpacing.lg,
        vertical: YtvSpacing.md,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(channel.name, style: textTheme.titleLarge),
                Text(
                  '由官方页面承载播放',
                  style: textTheme.bodySmall
                      ?.copyWith(color: YtvColors.textSecondary),
                ),
              ],
            ),
          ),
          if (listenable != null)
            ValueListenableBuilder<bool>(
              valueListenable: listenable,
              builder: (context, isFullscreen, _) => TextButton.icon(
                onPressed: () => gateway?.setFullscreen(!isFullscreen),
                icon: Icon(
                  isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
                ),
                label: Text(isFullscreen ? '退出全屏' : '全屏'),
              ),
            ),
          const SizedBox(width: YtvSpacing.sm),
          TextButton.icon(
            onPressed: onExit,
            icon: const Icon(Icons.arrow_back),
            label: const Text('返回'),
          ),
          Text(
            'Esc',
            style:
                textTheme.bodySmall?.copyWith(color: YtvColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _NoticePane extends StatelessWidget {
  const _NoticePane({
    required this.icon,
    required this.title,
    required this.detail,
    this.busy = false,
    this.onRetry,
    this.officialAddress,
  });

  final IconData icon;
  final String title;
  final String detail;
  final bool busy;
  final VoidCallback? onRetry;

  /// 非空时显示官方地址，供用户自行在浏览器打开。
  final String? officialAddress;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(YtvSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (busy)
              const SizedBox(
                width: 36,
                height: 36,
                child: CircularProgressIndicator(strokeWidth: 3),
              )
            else
              Icon(icon, size: 40, color: YtvColors.textSecondary),
            const SizedBox(height: YtvSpacing.lg),
            Text(title, style: textTheme.titleMedium, textAlign: TextAlign.center),
            const SizedBox(height: YtvSpacing.xs),
            Text(
              detail,
              style:
                  textTheme.bodyMedium?.copyWith(color: YtvColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            if (officialAddress != null) ...[
              const SizedBox(height: YtvSpacing.sm),
              SelectableText(
                officialAddress!,
                style: textTheme.bodySmall
                    ?.copyWith(color: YtvColors.textSecondary),
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: YtvSpacing.lg),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('重试'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 白名单审计条：只显示被拦截的主机名，不含路径与查询参数。
class _BlockedHostsStrip extends StatelessWidget {
  const _BlockedHostsStrip({required this.hosts});

  final Set<String> hosts;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(top: YtvSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '已阻止非官方域名：${hosts.join('、')}',
            style:
                textTheme.bodySmall?.copyWith(color: YtvColors.stateWarning),
          ),
          Text(
            '仅供白名单审计，不含路径与参数。',
            style:
                textTheme.bodySmall?.copyWith(color: YtvColors.textSecondary),
          ),
        ],
      ),
    );
  }
}