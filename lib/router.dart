import 'package:espresso_log/features/scaffold/root_scaffold.dart';
import 'package:espresso_log/features/history/history.dart';
import 'package:espresso_log/features/home/home.dart';
import 'package:espresso_log/features/settings/recorder.dart';
import 'package:espresso_log/features/settings/settings.dart';
import 'package:espresso_log/features/shot/shot_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:talker_flutter/talker_flutter.dart';

class AppRouter {
  GoRouter? router;
  final _homeTabNavigatorKey = GlobalKey<NavigatorState>();
  final _historyTabNavigatorKey = GlobalKey<NavigatorState>();
  final _settingsTabNavigatorKey = GlobalKey<NavigatorState>();

  static const homePath = '/';
  static const historyPath = '/history';
  static const settingsPath = '/settings';
  static const settingsLogPath = '/settings/log';
  static const settingsRecorderPath = '/settings/recorder';

  AppRouter(Talker talker, GlobalKey<NavigatorState> rootNavigatorKey) {
    router = GoRouter(
      observers: [TalkerRouteObserver(talker)],
      initialLocation: '/',
      navigatorKey: rootNavigatorKey,
      routes: [
        StatefulShellRoute.indexedStack(
          parentNavigatorKey: rootNavigatorKey,
          branches: [
            StatefulShellBranch(
              navigatorKey: _homeTabNavigatorKey,
              routes: [
                GoRoute(
                  path: homePath,
                  builder: (context, state) {
                    return const HomeScreen();
                  },
                ),
              ],
            ),
            StatefulShellBranch(
              navigatorKey: _historyTabNavigatorKey,
              routes: [
                GoRoute(
                  path: historyPath,
                  builder: (context, state) {
                    return const HistoryScreen();
                  },
                ),
              ],
            ),
            StatefulShellBranch(
              navigatorKey: _settingsTabNavigatorKey,
              routes: [
                GoRoute(
                  path: settingsPath,
                  builder: (context, state) {
                    return const SettingsScreen();
                  },
                ),
                GoRoute(
                  path: settingsLogPath,
                  builder: (context, state) {
                    return TalkerScreen(talker: talker);
                  },
                ),
                GoRoute(
                  path: settingsRecorderPath,
                  builder: (context, state) {
                    return const RecorderScreen();
                  },
                ),
              ],
            ),
          ],
          builder:
              (
                BuildContext context,
                GoRouterState state,
                StatefulNavigationShell navigationShell,
              ) {
                return RootScaffold(child: navigationShell);
              },
        ),
        GoRoute(
          path: '/shot',
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) {
            return ShotScreen();
          },
        ),
      ],
    );
  }
}
