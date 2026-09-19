import 'package:flutter/material.dart';

import '../../domain/models/channel.dart';
import '../theme/ytv_tokens.dart';
import 'focus_ring.dart';

/// 频道卡片：16:9 视觉区承载频道名，下方为当前节目。
///
/// 状态覆盖默认、悬停、焦点、收藏、不可用。
class ChannelCard extends StatelessWidget {
  const ChannelCard({
    super.key,
    required this.channel,
    this.programTitle,
    this.isFavorite = false,
    this.onPressed,
    this.onFavoriteToggle,
    this.width,
  });

  /// 元信息行固定高度，保证卡片高度可预测，避免在轨道内溢出。
  static const _metaRowHeight = 24.0;

  final Channel channel;
  final String? programTitle;
  final bool isFavorite;
  final VoidCallback? onPressed;
  final VoidCallback? onFavoriteToggle;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final restricted = channel.availability == ChannelAvailability.restricted;

    return FocusRing(
      onPressed: onPressed,
      scaleOnFocus: true,
      builder: (context, state) {
        final tileColor =
            state.focused || state.hovered ? YtvColors.elevated : YtvColors.surface;

        return Opacity(
          opacity: restricted ? 0.55 : 1,
          child: SizedBox(
            width: width,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                AspectRatio(
                  aspectRatio: YtvLayout.cardAspectRatio,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(YtvRadius.card),
                    child: ColoredBox(
                      color: tileColor,
                      child: Stack(
                        children: [
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(YtvSpacing.md),
                              child: Text(
                                channel.name,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: textTheme.headlineSmall,
                              ),
                            ),
                          ),
                          if (isFavorite)
                            const Positioned(
                              top: YtvSpacing.xs,
                              right: YtvSpacing.xs,
                              child: Icon(
                                Icons.favorite,
                                size: 18,
                                color: YtvColors.brandPrimary,
                              ),
                            ),
                          if (restricted)
                            const Positioned(
                              left: YtvSpacing.xs,
                              bottom: YtvSpacing.xs,
                              child: _RestrictedBadge(),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: YtvSpacing.xs),
                SizedBox(
                  height: _metaRowHeight,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          programTitle ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodySmall
                              ?.copyWith(color: YtvColors.textSecondary),
                        ),
                      ),
                      if (onFavoriteToggle != null)
                        FocusRing(
                          borderRadius: 999,
                          onPressed: onFavoriteToggle,
                          builder: (context, state) => Tooltip(
                            message: isFavorite ? '取消收藏' : '加入收藏',
                            child: Icon(
                              isFavorite ? Icons.favorite : Icons.favorite_border,
                              size: 18,
                              color: state.focused
                                  ? YtvColors.focusRing
                                  : YtvColors.textSecondary,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _RestrictedBadge extends StatelessWidget {
  const _RestrictedBadge();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: YtvColors.canvas,
        borderRadius: BorderRadius.circular(YtvRadius.card / 2),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: YtvSpacing.xs,
          vertical: 2,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline, size: 12, color: YtvColors.stateWarning),
            const SizedBox(width: 4),
            Text(
              '受限',
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: YtvColors.stateWarning),
            ),
          ],
        ),
      ),
    );
  }
}