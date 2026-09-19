import 'package:flutter/material.dart';

import '../../application/ytv_scope.dart';
import '../../domain/models/channel.dart';
import '../routes.dart';
import '../theme/ytv_tokens.dart';
import '../widgets/app_shell.dart';
import '../widgets/channel_card.dart';
import '../widgets/channel_catalog_view.dart';
import '../widgets/focus_ring.dart';
import 'player_page.dart';

/// 频道页：分类筛选、搜索、收藏切换。
class ChannelsPage extends StatefulWidget {
  const ChannelsPage({super.key});

  @override
  State<ChannelsPage> createState() => _ChannelsPageState();
}

class _ChannelsPageState extends State<ChannelsPage> {
  static const _categories = <({String label, ChannelCategory? value})>[
    (label: '全部', value: null),
    (label: 'CCTV', value: ChannelCategory.cctv),
    (label: '卫视', value: ChannelCategory.satellite),
  ];

  final TextEditingController _query = TextEditingController();
  ChannelCategory? _category;

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  List<Channel> _filter(List<Channel> channels) {
    final keyword = _query.text.trim().toLowerCase();
    return channels.where((channel) {
      if (_category != null && channel.category != _category) return false;
      if (keyword.isEmpty) return true;
      return channel.name.toLowerCase().contains(keyword);
    }).toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final store = YtvScope.of(context);
    final textTheme = Theme.of(context).textTheme;

    return AppShell(
      currentRoute: Routes.channels,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('频道', style: textTheme.headlineMedium),
          const SizedBox(height: YtvSpacing.lg),
          SizedBox(
            width: 360,
            child: TextField(
              controller: _query,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: '搜索频道',
                prefixIcon: const Icon(Icons.search, size: 20),
                filled: true,
                fillColor: YtvColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(YtvRadius.card),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(height: YtvSpacing.md),
          Row(
            children: [
              for (final category in _categories)
                Padding(
                  padding: const EdgeInsets.only(right: YtvSpacing.xs),
                  child: _CategoryChip(
                    label: category.label,
                    selected: _category == category.value,
                    onPressed: () => setState(() => _category = category.value),
                  ),
                ),
            ],
          ),
          const SizedBox(height: YtvSpacing.lg),
          Expanded(
            child: ChannelCatalogView(
              emptyMessage: '没有匹配的频道',
              isEmpty: (channels) => _filter(channels).isEmpty,
              builder: (context, channels) {
                final visible = _filter(channels);
                return ListView(
                  children: [
                    Wrap(
                      spacing: YtvSpacing.md,
                      runSpacing: YtvSpacing.md,
                      children: [
                        for (final channel in visible)
                          ChannelCard(
                            channel: channel,
                            width: 280,
                            isFavorite: store.isFavorite(channel.id),
                            onPressed: () => openPlayer(context, channel),
                            onFavoriteToggle: () =>
                                store.toggleFavorite(channel.id),
                          ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FocusRing(
      borderRadius: 999,
      onPressed: onPressed,
      builder: (context, state) => DecoratedBox(
        decoration: BoxDecoration(
          color: selected ? YtvColors.elevated : YtvColors.surface,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: YtvSpacing.md,
            vertical: YtvSpacing.xs,
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: selected || state.focused
                      ? YtvColors.textPrimary
                      : YtvColors.textSecondary,
                ),
          ),
        ),
      ),
    );
  }
}