import 'package:flutter/material.dart';

import '../../application/ytv_scope.dart';
import '../routes.dart';
import '../theme/ytv_tokens.dart';
import '../widgets/app_shell.dart';
import '../widgets/focus_ring.dart';

/// 设置页。不包含官方账号凭据管理，也不提供未实现的开关。
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = YtvScope.of(context);
    final textTheme = Theme.of(context).textTheme;

    return AppShell(
      currentRoute: Routes.settings,
      child: ListView(
        children: [
          Text('设置', style: textTheme.headlineMedium),
          const SizedBox(height: YtvSpacing.lg),
          const _SettingRow(
            label: '外观',
            value: '深色（当前唯一主题）',
          ),
          const _SettingRow(
            label: '官方账号',
            value: '在官方页面内自行登录，YTV 不保存或导出凭据',
          ),
          _SettingRow(
            label: '本地数据',
            value: '收藏 ${store.favoriteIds.length} 个频道 · 观看记录 ${store.recent.length} 条',
          ),
          const SizedBox(height: YtvSpacing.xl),
          Align(
            alignment: Alignment.centerLeft,
            child: _ActionButton(
              label: '清除本地历史',
              onPressed: () async {
                await store.clearHistory();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('已清除本地历史'),
                    duration: Duration(seconds: 3),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: YtvSpacing.xxl),
          Text(
            'YTV 0.1.0-dev · Phase 1A 工程与视觉骨架',
            style: textTheme.bodySmall?.copyWith(color: YtvColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: YtvSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 120, child: Text(label, style: textTheme.bodyLarge)),
          Expanded(
            child: Text(
              value,
              style: textTheme.bodyMedium
                  ?.copyWith(color: YtvColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FocusRing(
      onPressed: onPressed,
      builder: (context, state) => DecoratedBox(
        decoration: BoxDecoration(
          color: state.focused || state.hovered
              ? YtvColors.elevated
              : YtvColors.surface,
          borderRadius: BorderRadius.circular(YtvRadius.card),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: YtvSpacing.lg,
            vertical: YtvSpacing.sm,
          ),
          child: Text(label, style: Theme.of(context).textTheme.labelLarge),
        ),
      ),
    );
  }
}