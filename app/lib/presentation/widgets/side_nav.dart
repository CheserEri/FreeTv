import 'package:flutter/material.dart';

import '../routes.dart';
import '../theme/ytv_tokens.dart';
import 'focus_ring.dart';

/// 固定左侧导航。焦点与当前项使用品牌色指示条，均不依赖颜色单独传达状态。
class SideNav extends StatelessWidget {
  const SideNav({super.key, required this.currentRoute, required this.onSelect});

  final String currentRoute;
  final ValueChanged<String> onSelect;

  static const _items = <({String route, IconData icon, String label})>[
    (route: Routes.home, icon: Icons.home_outlined, label: '首页'),
    (route: Routes.channels, icon: Icons.live_tv_outlined, label: '频道'),
    (route: Routes.favorites, icon: Icons.favorite_border, label: '收藏'),
    (route: Routes.settings, icon: Icons.settings_outlined, label: '设置'),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: YtvLayout.sideNavWidth,
      child: Padding(
        padding: const EdgeInsets.all(YtvSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.only(
                left: YtvSpacing.md,
                top: YtvSpacing.md,
                bottom: YtvSpacing.lg,
              ),
              child: Text(
                'FreeTv',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2,
                  color: YtvColors.textPrimary,
                ),
              ),
            ),
            for (final item in _items)
              Padding(
                padding: const EdgeInsets.only(bottom: YtvSpacing.xs),
                child: _NavItem(
                  icon: item.icon,
                  label: item.label,
                  selected: currentRoute == item.route,
                  onPressed: () => onSelect(item.route),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FocusRing(
      onPressed: onPressed,
      builder: (context, state) {
        final emphasized = selected || state.focused;
        return DecoratedBox(
          decoration: BoxDecoration(
            color: state.hovered || selected ? YtvColors.elevated : Colors.transparent,
            borderRadius: BorderRadius.circular(YtvRadius.card),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: YtvSpacing.md,
              vertical: YtvSpacing.sm,
            ),
            child: Row(
              children: [
                Container(
                  width: 3,
                  height: 20,
                  decoration: BoxDecoration(
                    color: selected ? YtvColors.brandPrimary : Colors.transparent,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: YtvSpacing.sm),
                Icon(
                  icon,
                  size: 20,
                  color: emphasized ? YtvColors.textPrimary : YtvColors.textSecondary,
                ),
                const SizedBox(width: YtvSpacing.sm),
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: emphasized
                            ? YtvColors.textPrimary
                            : YtvColors.textSecondary,
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