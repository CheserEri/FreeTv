import 'package:flutter/material.dart';

import 'ytv_tokens.dart';

/// 由设计令牌构建的深色主题。首次版本只做深色主题，浅色主题留作令牌扩展。
ThemeData buildYtvTheme() {
  const scheme = ColorScheme.dark(
    primary: YtvColors.brandPrimary,
    onPrimary: YtvColors.textPrimary,
    secondary: YtvColors.focusRing,
    onSecondary: YtvColors.canvas,
    surface: YtvColors.surface,
    onSurface: YtvColors.textPrimary,
    error: YtvColors.stateWarning,
    onError: YtvColors.canvas,
  );

  final base = ThemeData(useMaterial3: true, colorScheme: scheme);

  return base.copyWith(
    scaffoldBackgroundColor: YtvColors.canvas,
    canvasColor: YtvColors.canvas,
    splashFactory: NoSplash.splashFactory,
    // 焦点表现由组件自行绘制（2px 外环 + 1.03 放大），不使用系统高亮。
    focusColor: Colors.transparent,
    hoverColor: Colors.transparent,
    highlightColor: Colors.transparent,
    dividerTheme: const DividerThemeData(color: YtvColors.elevated, thickness: 1),
    textTheme: base.textTheme.apply(
      bodyColor: YtvColors.textPrimary,
      displayColor: YtvColors.textPrimary,
      fontFamilyFallback: YtvTypography.fontFallback,
    ),
  );
}