import 'package:flutter/material.dart';

import '../theme/ytv_tokens.dart';

/// 供组件使用的焦点与悬停状态。
@immutable
class FocusVisualState {
  const FocusVisualState({required this.focused, required this.hovered});

  final bool focused;
  final bool hovered;
}

typedef FocusRingBuilder = Widget Function(BuildContext context, FocusVisualState state);

/// 统一的焦点表现：2px 外环，可选轻微放大，不依赖 hover。
///
/// 同时负责把获得焦点的组件滚动到可见区域。
class FocusRing extends StatefulWidget {
  const FocusRing({
    super.key,
    required this.builder,
    this.onPressed,
    this.borderRadius = YtvRadius.card,
    this.scaleOnFocus = false,
  });

  final FocusRingBuilder builder;
  final VoidCallback? onPressed;
  final double borderRadius;
  final bool scaleOnFocus;

  @override
  State<FocusRing> createState() => _FocusRingState();
}

class _FocusRingState extends State<FocusRing> {
  bool _focused = false;
  bool _hovered = false;

  void _handleFocusChange(bool hasFocus) {
    setState(() => _focused = hasFocus);
    if (hasFocus && Scrollable.maybeOf(context) != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content = Container(
      padding: const EdgeInsets.all(YtvLayout.focusRingWidth),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.borderRadius + YtvLayout.focusRingWidth),
        border: Border.all(
          color: _focused ? YtvColors.focusRing : Colors.transparent,
          width: YtvLayout.focusRingWidth,
        ),
      ),
      child: widget.builder(
        context,
        FocusVisualState(focused: _focused, hovered: _hovered),
      ),
    );

    if (widget.scaleOnFocus) {
      content = AnimatedScale(
        scale: _focused ? YtvLayout.focusScale : 1,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOut,
        child: content,
      );
    }

    return FocusableActionDetector(
      onFocusChange: _handleFocusChange,
      onShowHoverHighlight: (value) => setState(() => _hovered = value),
      mouseCursor: SystemMouseCursors.click,
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            widget.onPressed?.call();
            return null;
          },
        ),
      },
      child: GestureDetector(
        onTap: widget.onPressed,
        behavior: HitTestBehavior.opaque,
        child: content,
      ),
    );
  }
}