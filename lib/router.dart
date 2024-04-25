import 'package:espresso_log/ui/home/current-weight/current_weight_cubit.dart';
import 'package:espresso_log/ui/home/timer/timer_cubit.dart';
import 'package:espresso_log/ui/home/weight-change/weight_change_cubit.dart';
import 'package:espresso_log/ui/scaffold/bottom_navigation.dart';
import 'package:espresso_log/ui/history/history.dart';
import 'package:espresso_log/ui/home/home.dart';
import 'package:espresso_log/ui/scaffold/screen_container.dart';
import 'package:espresso_log/ui/settings/settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
                  builder: (context, state) {
                    return MultiBlocProvider(
                        providers: [
                          BlocProvider(create: (_) => CurrentWeightCubit()),
                          BlocProvider(create: (_) => WeightChangeCubit()),
                          BlocProvider(create: (_) => TimerCubit()),
                        ],
                        child: ScreenContainer(
                          key: state.pageKey,
                          child: const HomeScreen(),
                        ));
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
