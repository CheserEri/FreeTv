import 'package:flutter/material.dart';

import '../../domain/models/channel.dart';
import '../theme/ytv_tokens.dart';
import 'channel_card.dart';

/// 横向可滚动频道行。
class ChannelRail extends StatelessWidget {
  const ChannelRail({
    super.key,
    required this.title,
    required this.channels,
    required this.onChannelPressed,
    this.onFavoriteToggle,
    this.isFavorite,
    this.programTitleOf,
    this.emptyMessage = '暂无频道',
  });

  final String title;
  final List<Channel> channels;
  final ValueChanged<Channel> onChannelPressed;
  final ValueChanged<Channel>? onFavoriteToggle;
  final bool Function(Channel channel)? isFavorite;
  final String? Function(Channel channel)? programTitleOf;
  final String emptyMessage;

  /// 卡片高度 = 16:9 视觉区 + 间距 + 元信息行 + 焦点外环，另留缩放余量。
  static const _railHeight =
      YtvLayout.railCardWidth / YtvLayout.cardAspectRatio + 60;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: textTheme.titleLarge),
        const SizedBox(height: YtvSpacing.sm),
        if (channels.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: YtvSpacing.md),
            child: Text(
              emptyMessage,
              style: textTheme.bodyMedium?.copyWith(color: YtvColors.textSecondary),
            ),
          )
        else
          SizedBox(
            height: _railHeight,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(vertical: YtvSpacing.xs),
              itemCount: channels.length,
              separatorBuilder: (_, _) => const SizedBox(width: YtvSpacing.md),
              itemBuilder: (context, index) {
                final channel = channels[index];
                return Center(
                  child: ChannelCard(
                    channel: channel,
                    width: YtvLayout.railCardWidth,
                    programTitle: programTitleOf?.call(channel),
                    isFavorite: isFavorite?.call(channel) ?? false,
                    onPressed: () => onChannelPressed(channel),
                    onFavoriteToggle: onFavoriteToggle == null
                        ? null
                        : () => onFavoriteToggle!(channel),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}