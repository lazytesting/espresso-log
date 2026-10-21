import 'package:espresso_log/domain/shot/abstract_shot_clock.dart';
import 'package:espresso_log/domain/settings/settings_repository.dart';
import 'package:espresso_log/domain/shot/auto_start_stop_rule.dart';
import 'package:espresso_log/domain/shot/drip_end_rule.dart';
import 'package:espresso_log/domain/shot/auto_tare_rule.dart';
import 'package:espresso_log/domain/telemetry/pressure_repository.dart';
import 'package:espresso_log/domain/telemetry/scale_repository.dart';
import 'package:espresso_log/ui/scaffold/root_scaffold.dart';
import 'package:espresso_log/ui/history/history.dart';
import 'package:espresso_log/ui/home/home.dart';
import 'package:espresso_log/ui/settings/recorder.dart';
import 'package:espresso_log/ui/settings/settings.dart';
import 'package:espresso_log/ui/shot/shot_graph/shot_graph_cubit.dart';
import 'package:espresso_log/ui/shot/shot_screen.dart';
import 'package:espresso_log/ui/shot/timer/timer_cubit.dart';
import 'package:espresso_log/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
                    return TalkerScreen(
                      talker: talker,
                      appBarTitle: 'Logs',
                      theme: const TalkerScreenTheme(
                        backgroundColor: kBackgroundColor,
                        cardColor: kSurfaceColor,
                      ),
                    );
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
            return BlocProvider(
              create: (_) {
                context.read<TimerCubit>().reset();
                return ShotGraphCubit(
                  context.read<AbstractAutoStartStopRule>(),
                  context.read<ScaleRepository>(),
                  context.read<AbstractShotClock>(),
                  context.read<AbstractAutoTareRule>(),
                  context.read<PressureRepository>(),
                  context.read<AbstractDripEndRule>(),
                  context.read<SettingsRepository>(),
                  talker: context.read<Talker>(),
                )..start();
              },
              child: const ShotScreen(),
            );
          },
        ),
      ],
    );
  }
}
