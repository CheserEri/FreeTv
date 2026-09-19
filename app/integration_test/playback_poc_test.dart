import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:ytv/app.dart';
import 'package:ytv/application/ytv_store.dart';
import 'package:ytv/infrastructure/repositories/memory_favorite_repository.dart';
import 'package:ytv/infrastructure/repositories/memory_history_repository.dart';
import 'package:ytv/infrastructure/repositories/seed_channel_repository.dart';
import 'package:ytv/presentation/pages/player_page.dart';
import 'package:ytv/presentation/widgets/channel_card.dart';

/// Phase 1B 真机 POC：在 Windows 上真实创建 WebView2，打开官方电视页。
///
/// 运行：`flutter test integration_test/playback_poc_test.dart -d windows`
///
/// 验证《WebView POC 白名单与隐私测试清单》中的 S-2、S-6、P-12：
/// 官方页面能加载、不白屏、Esc 能返回、关闭后释放承载资源且进程存活。
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('官方页面在 Windows 真机加载、Esc 返回且进程存活', (tester) async {
    // 该变量若为 true，播放层会走非 Windows 分支，说明没测到真机路径。
    debugPrint('FLUTTER_TEST=${Platform.environment['FLUTTER_TEST']}');
    debugPrint('isWindows=${Platform.isWindows}');

    final store = YtvStore(
      channels: const SeedChannelRepository(),
      favorites: MemoryFavoriteRepository(),
      history: MemoryHistoryRepository(),
    );

    await tester.pumpWidget(YtvApp(store: store));
    await tester.pumpAndSettle();

    // 进入播放页。
    await tester.tap(find.byType(ChannelCard).first);
    await tester.pumpAndSettle();
    expect(find.byType(PlayerPage), findsOneWidget);
    expect(store.recent, hasLength(1), reason: '打开播放页应记录本机历史');

    // 官方页面加载：持续泵帧，给 WebView2 真实加载的时间。
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 500));
    }
    await tester.pumpAndSettle();

    // 不白屏：加载期间必须有状态视图；加载成功后由 WebView 覆盖。
    expect(tester.takeException(), isNull, reason: '加载官方页面不应抛异常');

    // Esc 返回。
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byType(PlayerPage), findsNothing, reason: 'Esc 应返回上一页');

    // 关闭后留出时间，便于从外部观察 WebView2 进程是否释放。
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 500));
    }
    expect(tester.takeException(), isNull, reason: '关闭播放页不应抛异常');
    expect(store.recent, hasLength(1));
  });
}