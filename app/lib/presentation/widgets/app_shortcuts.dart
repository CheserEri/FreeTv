import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../routes.dart';

/// 记录当前路由名，供 Esc 返回的兜底判断使用。
class RouteTracker extends NavigatorObserver {
  String _current = Routes.home;

  String get current => _current;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _current = route.settings.name ?? _current;
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    _current = newRoute?.settings.name ?? _current;
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (previousRoute != null) {
      _current = previousRoute.settings.name ?? _current;
    }
  }
}

/// 全局键盘动作。
///
/// 挂在 Navigator 之上，因此任何页面、任何焦点状态下 Esc 都能生效。
class AppShortcuts extends StatelessWidget {
  const AppShortcuts({
    super.key,
    required this.navigatorKey,
    required this.tracker,
    required this.child,
  });

  final GlobalKey<NavigatorState> navigatorKey;
  final RouteTracker tracker;
  final Widget child;

  void _handleBack() {
    final navigator = navigatorKey.currentState;
    if (navigator == null) return;

    if (navigator.canPop()) {
      navigator.pop();
      return;
    }
    if (tracker.current != Routes.home) {
      navigator.pushNamedAndRemoveUntil(Routes.home, (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.escape): _BackIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          _BackIntent: CallbackAction<_BackIntent>(
            onInvoke: (_) {
              _handleBack();
              return null;
            },
          ),
        },
        child: child,
      ),
    );
  }
}

class _BackIntent extends Intent {
  const _BackIntent();
}