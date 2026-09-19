import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ytv/app.dart';
import 'package:ytv/application/ytv_store.dart';
import 'package:ytv/domain/models/channel.dart';
import 'package:ytv/infrastructure/official_pages.dart';
import 'package:ytv/infrastructure/official_url_policy.dart';
import 'package:ytv/infrastructure/repositories/memory_favorite_repository.dart';
import 'package:ytv/infrastructure/repositories/memory_history_repository.dart';
import 'package:ytv/infrastructure/repositories/seed_channel_repository.dart';
import 'package:ytv/presentation/pages/channels_page.dart';
import 'package:ytv/presentation/pages/favorites_page.dart';
import 'package:ytv/presentation/pages/home_page.dart';
import 'package:ytv/presentation/pages/player_page.dart';
import 'package:ytv/presentation/pages/settings_page.dart';
import 'package:ytv/presentation/widgets/channel_card.dart';

YtvStore buildStore() => YtvStore(
      channels: const SeedChannelRepository(),
      favorites: MemoryFavoriteRepository(),
      history: MemoryHistoryRepository(),
    );

Future<void> pumpApp(WidgetTester tester, YtvStore store) async {
  tester.view.physicalSize = const Size(1400, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(YtvApp(store: store));
  await tester.pumpAndSettle();
}

Finder get _horizontalRail => find.byWidgetPredicate(
      (widget) => widget is ListView && widget.scrollDirection == Axis.horizontal,
    );

void main() {
  group('离线频道目录', () {
    test('无网络即可返回完整的内置目录', () async {
      const repository = SeedChannelRepository();
      final channels = await repository.list();
      expect(channels, hasLength(73));
      expect(
        await repository.list(category: ChannelCategory.cctv),
        hasLength(40),
      );
      expect(
        await repository.list(category: ChannelCategory.satellite),
        hasLength(32),
      );
      expect(
        await repository.list(category: ChannelCategory.other),
        hasLength(1),
      );
    });

    test('按分类筛选与关键词搜索', () async {
      const repository = SeedChannelRepository();
      expect(await repository.search('湖南'), hasLength(1));
      expect(await repository.search('cctv'), hasLength(34));
      expect(await repository.search('不存在的频道'), isEmpty);
      expect(await repository.getById('cctv-1'), isNotNull);
      expect(await repository.getById('satellite-hunan'), isNotNull);
      expect(await repository.getById('missing'), isNull);
    });

    test('每个频道都登记了可直达的单频道官方地址', () async {
      const repository = SeedChannelRepository();
      final channels = await repository.list();

      for (final channel in channels) {
        expect(
          channel.officialPageUrl,
          startsWith('${OfficialPages.tvHome}?pid='),
          reason: '${channel.id} 缺少单频道直达地址',
        );
        expect(
          OfficialUrlPolicy.check(channel.officialPageUrl).allowed,
          isTrue,
          reason: '${channel.id} 的地址未通过官方白名单判定',
        );
      }

      // pid 唯一，避免两个频道落在同一个官方频道上。
      final addresses = channels.map((c) => c.officialPageUrl).toSet();
      expect(addresses, hasLength(channels.length));
    });
  });

  group('首页', () {
    testWidgets('不联网也能浏览全部内置频道', (tester) async {
      await pumpApp(tester, buildStore());

      expect(find.text('焦点频道'), findsOneWidget);
      expect(find.text('CCTV1'), findsAtLeastNWidgets(1));

      // CCTV 横向轨道按需构建，滚到末尾确认内置目录可完整浏览。
      expect(_horizontalRail, findsOneWidget);
      final railPosition = tester
          .state<ScrollableState>(
            find.descendant(
              of: _horizontalRail,
              matching: find.byType(Scrollable),
            ),
          )
          .position;
      expect(railPosition.maxScrollExtent, greaterThan(0));
      railPosition.jumpTo(railPosition.maxScrollExtent);
      await tester.pumpAndSettle();
      expect(find.text('CCTV卫生健康频道'), findsOneWidget);
    });

    testWidgets('点击频道进入播放页、记录历史并可返回', (tester) async {
      final store = buildStore();
      await pumpApp(tester, store);

      await tester.tap(find.byType(ChannelCard).first);
      await tester.pumpAndSettle();

      expect(find.byType(PlayerPage), findsOneWidget);
      expect(store.recent, hasLength(1));
      expect(store.recent.single.channelId, 'cctv-1');

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byType(PlayerPage), findsNothing);
    });

    testWidgets('收藏切换实时反映在卡片上', (tester) async {
      final store = buildStore();
      await pumpApp(tester, store);

      final toggle = find
          .descendant(
            of: find.byType(ChannelCard).first,
            matching: find.byIcon(Icons.favorite_border),
          )
          .first;

      await tester.tap(toggle);
      await tester.pumpAndSettle();

      expect(store.favoriteIds, hasLength(1));
      expect(
        find.descendant(
          of: find.byType(ChannelCard).first,
          matching: find.byTooltip('取消收藏'),
        ),
        findsOneWidget,
      );
    });
  });

  group('页面导航', () {
    testWidgets('频道页支持分类筛选与搜索空态', (tester) async {
      await pumpApp(tester, buildStore());

      await tester.tap(find.text('频道'));
      await tester.pumpAndSettle();
      expect(find.byType(ChannelsPage), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byType(ChannelCard), findsAtLeastNWidgets(1));

      await tester.tap(find.text('卫视'));
      await tester.pumpAndSettle();
      expect(find.text('湖南卫视'), findsAtLeastNWidgets(1));

      await tester.tap(find.text('全部'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '湖南');
      await tester.pumpAndSettle();
      expect(find.text('湖南卫视'), findsAtLeastNWidgets(1));
      expect(find.byType(ChannelCard), findsOneWidget);
    });

    testWidgets('收藏页实时反映收藏变化', (tester) async {
      final store = buildStore();
      await pumpApp(tester, store);

      await tester.tap(find.text('收藏'));
      await tester.pumpAndSettle();
      expect(find.byType(FavoritesPage), findsOneWidget);
      expect(find.text('还没有收藏频道'), findsOneWidget);

      await tester.tap(find.text('频道'));
      await tester.pumpAndSettle();
      await tester.tap(
        find
            .descendant(
              of: find.byType(ChannelCard).first,
              matching: find.byIcon(Icons.favorite_border),
            )
            .first,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('收藏'));
      await tester.pumpAndSettle();
      expect(store.favoriteIds, hasLength(1));
      expect(find.byType(ChannelCard), findsOneWidget);
      expect(find.text('还没有收藏频道'), findsNothing);
    });

    testWidgets('设置页可清除本地历史', (tester) async {
      final store = buildStore();
      await pumpApp(tester, store);

      await tester.tap(find.byType(ChannelCard).first);
      await tester.pumpAndSettle();
      expect(store.recent, hasLength(1));
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      await tester.tap(find.text('设置'));
      await tester.pumpAndSettle();
      expect(find.byType(SettingsPage), findsOneWidget);
      expect(find.text('外观'), findsOneWidget);

      await tester.tap(find.text('清除本地历史'));
      await tester.pumpAndSettle();

      expect(store.recent, isEmpty);
      expect(find.text('已清除本地历史'), findsOneWidget);
    });

    testWidgets('Esc 在标签页回到首页', (tester) async {
      await pumpApp(tester, buildStore());

      await tester.tap(find.text('频道'));
      await tester.pumpAndSettle();
      expect(find.byType(ChannelsPage), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byType(HomePage), findsOneWidget);
    });
  });

  group('键盘焦点', () {
    testWidgets('Tab 与方向键持续移动焦点，不出现焦点丢失', (tester) async {
      await pumpApp(tester, buildStore());

      for (final key in <LogicalKeyboardKey>[
        LogicalKeyboardKey.tab,
        LogicalKeyboardKey.tab,
        LogicalKeyboardKey.arrowRight,
        LogicalKeyboardKey.arrowDown,
        LogicalKeyboardKey.arrowLeft,
        LogicalKeyboardKey.arrowUp,
      ]) {
        await tester.sendKeyEvent(key);
        await tester.pumpAndSettle();
        expect(
          FocusManager.instance.primaryFocus,
          isNotNull,
          reason: '按下 $key 后焦点不应丢失',
        );
      }
    });

    testWidgets('Enter 激活当前焦点组件', (tester) async {
      final store = buildStore();
      await pumpApp(tester, store);

      // Tab 前进直到焦点落在频道卡片内。
      for (var i = 0; i < 12; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pumpAndSettle();
        final context = FocusManager.instance.primaryFocus?.context;
        if (context != null &&
            context.findAncestorWidgetOfExactType<ChannelCard>() != null) {
          break;
        }
      }

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      final activated = store.favoriteIds.isNotEmpty ||
          find.byType(PlayerPage).evaluate().isNotEmpty;
      expect(activated, isTrue, reason: 'Enter 应触发焦点组件的主操作');
    });
  });

  group('设计令牌', () {
    test('色值只允许出现在 ytv_tokens.dart', () {
      final violations = <String>[];
      for (final entity in Directory('lib').listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        if (entity.path.endsWith('ytv_tokens.dart')) continue;
        if (RegExp(r'Color\(0x').hasMatch(entity.readAsStringSync())) {
          violations.add(entity.path);
        }
      }
      expect(violations, isEmpty, reason: '页面与组件不得硬编码色值');
    });
  });
}