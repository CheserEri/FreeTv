import 'package:flutter/material.dart';

import '../../application/ytv_scope.dart';
import '../routes.dart';
import '../theme/ytv_tokens.dart';
import '../widgets/app_shell.dart';
import '../widgets/channel_card.dart';
import '../widgets/channel_catalog_view.dart';
import 'player_page.dart';

/// 收藏页：本机收藏频道，添加与删除实时反映。
class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShell(
      currentRoute: Routes.favorites,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('收藏', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: YtvSpacing.lg),
          Expanded(
            child: ChannelCatalogView(
              emptyMessage: '还没有收藏频道',
              isEmpty: (channels) {
                final store = YtvScope.of(context);
                return !channels.any((channel) => store.isFavorite(channel.id));
              },
              builder: (context, channels) {
                final store = YtvScope.of(context);
                final favorites = channels
                    .where((channel) => store.isFavorite(channel.id))
                    .toList(growable: false);
                return ListView(
                  children: [
                    Wrap(
                      spacing: YtvSpacing.md,
                      runSpacing: YtvSpacing.md,
                      children: [
                        for (final channel in favorites)
                          ChannelCard(
                            channel: channel,
                            width: 280,
                            isFavorite: true,
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