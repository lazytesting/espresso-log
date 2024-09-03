import 'package:espresso_log/services/scale/abstract_scale_service.dart';
import 'package:espresso_log/router.dart';
import 'package:espresso_log/services/scale/decent_scale_service.dart';
import 'package:espresso_log/services/scale/mock_scale_service.dart';
import 'package:espresso_log/services/timer/abstract_timer_service.dart';
import 'package:espresso_log/services/timer/timer_service.dart';
import 'package:espresso_log/ui/home/current-weight/current_weight_cubit.dart';
import 'package:espresso_log/ui/home/timer/timer_cubit.dart';
import 'package:espresso_log/ui/home/weight-change/weight_change_cubit.dart';
import 'package:espresso_log/ui/home/weight_graph/weight_graph_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

const useMockScale =
    bool.fromEnvironment('USE_MOCK_SCALE', defaultValue: false);

final getIt = GetIt.instance;
void main() {
  getIt.registerSingleton<AbstractTimerService>(TimerService());
  getIt.registerSingletonAsync<AbstractScaleService>(() async {
    var scaleService;
    if (useMockScale) {
      scaleService = MockScaleService();
    } else {
      scaleService = DecentScaleService();
    }
    await scaleService.init();
    return scaleService;
  });

  runApp(MultiBlocProvider(providers: [
    BlocProvider(create: (_) => CurrentWeightCubit()),
    BlocProvider(create: (_) => WeightChangeCubit()),
    BlocProvider(create: (_) => TimerCubit()),
    BlocProvider(create: (_) => WeightGraphCubit()),
  ], child: const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  ThemeData _getTheme() {
    var baseTheme = ThemeData.from(
        colorScheme: ColorScheme.fromSeed(
            seedColor: const Color.fromARGB(255, 84, 48, 134)));

    return baseTheme;
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: getIt.allReady(),
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          if (snapshot.hasData) {
            return MaterialApp.router(
              theme: _getTheme(),
              routerConfig: AppRouter().router,
            );
          } else {
            return const CircularProgressIndicator();
          }
        });
  }
}
