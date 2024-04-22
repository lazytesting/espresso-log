import 'package:espresso_log/bottom_navigation.dart';
import 'package:espresso_log/history.dart';
import 'package:espresso_log/home.dart';
import 'package:espresso_log/settings.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppRouter {
  GoRouter? router;
  final _rootNavigatorKey = GlobalKey<NavigatorState>();
  final _homeTabNavigatorKey = GlobalKey<NavigatorState>();
  final _historyTabNavigatorKey = GlobalKey<NavigatorState>();
  final _settingsTabNavigatorKey = GlobalKey<NavigatorState>();

  static const homePath = '/home';
  static const historyPath = '/history';
  static const settingsPath = '/settings';

  AppRouter() {
    router = GoRouter(
      initialLocation: '/home',
      navigatorKey: _rootNavigatorKey,
      routes: [
        StatefulShellRoute.indexedStack(
          parentNavigatorKey: _rootNavigatorKey,
          branches: [
            StatefulShellBranch(
              navigatorKey: _homeTabNavigatorKey,
              routes: [
                GoRoute(
                  path: homePath,
                  pageBuilder: (context, GoRouterState state) {
                    return getPage(
                      child: const HomeScreen(),
                      state: state,
                    );
                  },
                ),
              ],
            ),
            StatefulShellBranch(
              navigatorKey: _historyTabNavigatorKey,
              routes: [
                GoRoute(
                  path: historyPath,
                  pageBuilder: (context, state) {
                    return getPage(
                      child: const HistoryScreen(),
                      state: state,
                    );
                  },
                ),
              ],
            ),
            StatefulShellBranch(
              navigatorKey: _settingsTabNavigatorKey,
              routes: [
                GoRoute(
                  path: settingsPath,
                  pageBuilder: (context, state) {
                    return getPage(
                      child: SettingsScreen(),
                      state: state,
                    );
                  },
                ),
              ],
            ),
          ],
          pageBuilder: (
            BuildContext context,
            GoRouterState state,
            StatefulNavigationShell navigationShell,
          ) {
            return getPage(
              child: BottomNavigationPage(
                child: navigationShell,
              ),
              state: state,
            );
          },
        ),
      ],
    );
  }

  Page getPage({
    required Widget child,
    required GoRouterState state,
  }) {
    return MaterialPage(
      key: state.pageKey,
      child: child,
    );
  }
}
