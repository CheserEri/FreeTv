import 'package:flutter/material.dart';

import '../theme/ytv_tokens.dart';
import 'focus_ring.dart';

/// 页面状态视图：loading / data / empty / error 四态。
class LoadStateView extends StatelessWidget {
  const LoadStateView({
    super.key,
    required this.isLoading,
    required this.errorMessage,
    required this.isEmpty,
    required this.emptyMessage,
    required this.onRetry,
    required this.builder,
  });

  final bool isLoading;
  final String? errorMessage;
  final bool isEmpty;
  final String emptyMessage;
  final VoidCallback onRetry;
  final WidgetBuilder builder;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: YtvColors.brandPrimary),
      );
    }

    final error = errorMessage;
    if (error != null) {
      return _Message(
        icon: Icons.error_outline,
        color: YtvColors.stateWarning,
        message: error,
        actionLabel: '重试',
        onAction: onRetry,
      );
    }

    if (isEmpty) {
      return _Message(
        icon: Icons.tv_off_outlined,
        color: YtvColors.textSecondary,
        message: emptyMessage,
      );
    }

    return builder(context);
  }
}

class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.color,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final Color color;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 40, color: color),
          const SizedBox(height: YtvSpacing.md),
          Text(
            message,
            textAlign: TextAlign.center,
            style: textTheme.bodyLarge?.copyWith(color: YtvColors.textSecondary),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: YtvSpacing.lg),
            FocusRing(
              onPressed: onAction,
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
                  child: Text(actionLabel!, style: textTheme.labelLarge),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}