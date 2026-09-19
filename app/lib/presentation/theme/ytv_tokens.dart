import 'package:flutter/material.dart';

/// YTV 设计令牌。所有色值与间距必须取自此处，页面与组件不得硬编码。
abstract final class YtvColors {
  static const canvas = Color(0xFF0B0D12);
  static const surface = Color(0xFF151922);
  static const elevated = Color(0xFF202633);
  static const textPrimary = Color(0xFFF5F7FA);
  static const textSecondary = Color(0xFFAAB3C2);
  static const brandPrimary = Color(0xFFE63B3F);
  static const focusRing = Color(0xFF74B9FF);
  static const stateWarning = Color(0xFFF3B949);
}

/// 8pt 间距体系。
abstract final class YtvSpacing {
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 48.0;
}

abstract final class YtvRadius {
  static const card = 12.0;
}

abstract final class YtvLayout {
  static const maxContentWidth = 1440.0;
  static const desktopGutter = 40.0;
  static const tvGutter = 72.0;
  static const sideNavWidth = 200.0;
  static const focusRingWidth = 2.0;
  static const focusScale = 1.03;
  static const cardAspectRatio = 16 / 9;
  static const railCardWidth = 260.0;
}

abstract final class YtvTypography {
  static const minBodySize = 14.0;
  static const minTvBodySize = 20.0;
  static const fontFallback = <String>['Microsoft YaHei', 'Noto Sans SC'];
}