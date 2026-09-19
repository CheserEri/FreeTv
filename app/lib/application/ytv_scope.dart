import 'package:flutter/widgets.dart';

import 'ytv_store.dart';

/// 向下传递本机状态。状态变化时依赖它的页面自动重建。
class YtvScope extends InheritedNotifier<YtvStore> {
  const YtvScope({super.key, required YtvStore store, required super.child})
      : super(notifier: store);

  static YtvStore of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<YtvScope>();
    assert(scope != null, 'YtvScope 未挂载：请确认页面位于 YtvApp 之下。');
    return scope!.notifier!;
  }
}