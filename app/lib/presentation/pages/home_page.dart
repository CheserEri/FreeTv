import 'package:flutter/material.dart';

import '../../application/ytv_scope.dart';
import '../../domain/models/channel.dart';
import '../routes.dart';
import '../theme/ytv_tokens.dart';
import '../widgets/app_shell.dart';
import '../widgets/channel_card.dart';
import '../widgets/channel_catalog_view.dart';
import '../widgets/channel_rail.dart';
import '../widgets/focus_ring.dart';
import 'player_page.dart';

/// 首页：焦点频道、继续观看、CCTV 横向列表。
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShell(
      currentRoute: Routes.home,
      child: ChannelCatalogView(
        builder: (context, channels) => _HomeContent(channels: channels),
      ),
    );
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent({required this.channels});

  final List<Channel> channels;

  @override
  Widget build(BuildContext context) {
    final store = YtvScope.of(context);
    final textTheme = Theme.of(context).textTheme;

    final byId = <String, Channel>{
      for (final channel in channels) channel.id: channel,
    };
    final recentChannels = <Channel>[
      for (final entry in store.recent)
        if (byId[entry.channelId] != null) byId[entry.channelId]!,
    ];
    final programTitles = <String, String>{
      for (final entry in store.recent)
        if (entry.lastProgramTitle != null) entry.channelId: entry.lastProgramTitle!,
    };
    final cctvChannels = channels
        .where((channel) => channel.category == ChannelCategory.cctv)
        .toList(growable: false);

    final focus = recentChannels.isNotEmpty ? recentChannels.first : channels.first;

    return ListView(
      children: [
        Row(
          children: [
            Expanded(child: Text(_greeting(), style: textTheme.headlineMedium)),
            _HeaderAction(
              icon: Icons.search,
              tooltip: '搜索频道',
              onPressed: () =>
                  Navigator.of(context).pushReplacementNamed(Routes.channels),
            ),
            const SizedBox(width: YtvSpacing.md),
            _HeaderAction(
              icon: Icons.settings_outlined,
              tooltip: '设置',
              onPressed: () =>
                  Navigator.of(context).pushReplacementNamed(Routes.settings),
            ),
          ],
        ),
        const SizedBox(height: YtvSpacing.xl),
        Text('焦点频道', style: textTheme.titleLarge),
        const SizedBox(height: YtvSpacing.sm),
        Align(
          alignment: Alignment.centerLeft,
          child: ChannelCard(
            channel: focus,
            width: 420,
            programTitle: programTitles[focus.id],
            isFavorite: store.isFavorite(focus.id),
            onPressed: () => openPlayer(context, focus),
            onFavoriteToggle: () => store.toggleFavorite(focus.id),
          ),
        ),
        const SizedBox(height: YtvSpacing.xl),
        ChannelRail(
          title: '继续观看',
          channels: recentChannels,
          emptyMessage: '还没有观看记录',
          onChannelPressed: (channel) => openPlayer(context, channel),
          isFavorite: (channel) => store.isFavorite(channel.id),
          onFavoriteToggle: (channel) => store.toggleFavorite(channel.id),
          programTitleOf: (channel) => programTitles[channel.id],
        ),
        const SizedBox(height: YtvSpacing.xl),
        ChannelRail(
          title: 'CCTV',
          channels: cctvChannels,
          onChannelPressed: (channel) => openPlayer(context, channel),
          isFavorite: (channel) => store.isFavorite(channel.id),
          onFavoriteToggle: (channel) => store.toggleFavorite(channel.id),
          programTitleOf: (channel) => programTitles[channel.id],
        ),
      ],
    );
  }

  static String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 6) return '凌晨好';
    if (hour < 12) return '早上好';
    if (hour < 18) return '下午好';
    return '晚上好';
  }
}

class _HeaderAction extends StatelessWidget {
  const _HeaderAction({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FocusRing(
      borderRadius: 999,
      onPressed: onPressed,
      builder: (context, state) => Tooltip(
        message: tooltip,
        child: Icon(
          icon,
          size: 22,
          color: state.focused ? YtvColors.focusRing : YtvColors.textSecondary,
        ),
      ),
    );
  }
}