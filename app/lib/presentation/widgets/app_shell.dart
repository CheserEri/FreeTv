import 'package:flutter/material.dart';

import '../theme/ytv_tokens.dart';
import 'side_nav.dart';

/// 主窗口外壳：左侧导航 + 内容区，负责内容区宽度与边距约束。
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.currentRoute, required this.child});

  final String currentRoute;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SideNav(
            currentRoute: currentRoute,
            onSelect: (route) => Navigator.of(context).pushReplacementNamed(route),
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: YtvLayout.maxContentWidth,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: YtvLayout.desktopGutter,
                    vertical: YtvSpacing.xl,
                  ),
                  child: child,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}