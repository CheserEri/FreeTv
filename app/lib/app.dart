import 'package:flutter/material.dart';

import 'application/ytv_scope.dart';
import 'application/ytv_store.dart';
import 'domain/models/channel.dart';
import 'presentation/pages/channels_page.dart';
import 'presentation/pages/favorites_page.dart';
import 'presentation/pages/home_page.dart';
import 'presentation/pages/player_page.dart';
import 'presentation/pages/settings_page.dart';
import 'presentation/routes.dart';
import 'presentation/theme/ytv_theme.dart';
import 'presentation/widgets/app_shortcuts.dart';

class YtvApp extends StatefulWidget {
  const YtvApp({super.key, required this.store});

  final YtvStore store;

  @override
  State<YtvApp> createState() => _YtvAppState();
}

class _YtvAppState extends State<YtvApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  final RouteTracker _routeTracker = RouteTracker();

  @override
  void initState() {
    super.initState();
    widget.store.load();
  }

  Route<void> _onGenerateRoute(RouteSettings settings) {
    return MaterialPageRoute<void>(
      settings: settings,
      builder: switch (settings.name) {
        Routes.channels => (_) => const ChannelsPage(),
        Routes.favorites => (_) => const FavoritesPage(),
        Routes.settings => (_) => const SettingsPage(),
        Routes.player => (_) {
            final channel = settings.arguments;
            if (channel is! Channel) return const HomePage();
            return PlayerPage(channel: channel);
          },
        _ => (_) => const HomePage(),
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return YtvScope(
      store: widget.store,
      child: MaterialApp(
        title: 'FreeTv',
        debugShowCheckedModeBanner: false,
        theme: buildYtvTheme(),
        navigatorKey: _navigatorKey,
        navigatorObservers: <NavigatorObserver>[_routeTracker],
        initialRoute: Routes.home,
        onGenerateRoute: _onGenerateRoute,
        builder: (context, child) => AppShortcuts(
          navigatorKey: _navigatorKey,
          tracker: _routeTracker,
          child: child ?? const SizedBox.shrink(),
        ),
      ),
    );
  }
}