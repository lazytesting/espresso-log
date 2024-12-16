import 'package:espresso_log/services/auto-start-stop/auto_start_stop_service.dart';
import 'package:espresso_log/services/pressure/abstract_pressure_service.dart';
import 'package:espresso_log/services/pressure/bookoo_pressure_service.dart';
import 'package:espresso_log/services/pressure/mock_pressure_service.dart';
import 'package:espresso_log/services/scale/abstract_scale_service.dart';
import 'package:espresso_log/router.dart';
import 'package:espresso_log/services/scale/decent_scale_service.dart';
import 'package:espresso_log/services/scale/mock_scale_service.dart';
import 'package:espresso_log/services/timer/abstract_timer_service.dart';
import 'package:espresso_log/services/timer/timer_service.dart';
import 'package:espresso_log/ui/home/auto-tare/auto_tare_cubit.dart';
import 'package:espresso_log/ui/home/current-weight/current_weight_cubit.dart';
import 'package:espresso_log/ui/home/pressure/pressure_cubit.dart';
import 'package:espresso_log/ui/home/shot_graph/shot_graph_cubit.dart';
import 'package:espresso_log/ui/home/timer/timer_cubit.dart';
import 'package:espresso_log/ui/home/weight-change/weight_change_cubit.dart';
import 'package:espresso_log/ui/home/weight_graph/weight_graph_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import 'services/bluetooth/bluetooth_service.dart';

const useMockScale =
    bool.fromEnvironment('USE_MOCK_SCALE', defaultValue: false);
const useMockPressure =
    bool.fromEnvironment('USE_MOCK_PRESSURE', defaultValue: false);

final getIt = GetIt.instance;
void main() async {
  getIt.registerSingletonAsync<BluetoothDevicesService>(() async {
    BluetoothDevicesService bluetoothService = BluetoothDevicesService();
    await bluetoothService.init();
    return bluetoothService;
  });

  getIt.registerSingleton<AbstractTimerService>(TimerService());
  getIt.registerSingletonAsync<AbstractScaleService>(() async {
    AbstractScaleService scaleService;
    if (useMockScale) {
      scaleService = MockScaleService();
    } else {
      await getIt.isReady<BluetoothDevicesService>();
      scaleService = DecentScaleService(getIt.get<BluetoothDevicesService>());
    }
    await scaleService.init();
    return scaleService;
  });

  getIt.registerSingletonAsync<AbstractPressureService>(() async {
    AbstractPressureService pressureService;
    if (useMockPressure) {
      pressureService = MockPressureService();
    } else {
      await getIt.isReady<BluetoothDevicesService>();
      pressureService =
          BookooPressureService(getIt.get<BluetoothDevicesService>());
    }
    await pressureService.init();
    return pressureService;
  });

  getIt.registerSingletonAsync<AutoStartStopService>(() async {
    await getIt.isReady<AbstractPressureService>();
    var timerService = getIt.get<AbstractTimerService>();
    var pressureService = getIt.get<AbstractPressureService>();
    return AutoStartStopService(pressureService, timerService);
  });

  runApp(MultiBlocProvider(providers: [
    BlocProvider(create: (_) => ShotGraphCubit()),
    BlocProvider(create: (_) => CurrentWeightCubit()),
    BlocProvider(create: (_) => WeightChangeCubit()),
    BlocProvider(create: (_) => TimerCubit()),
    BlocProvider(create: (_) => WeightGraphCubit()),
    BlocProvider(create: (_) => AutoTareCubit()),
    BlocProvider(create: (_) => PressureCubit())
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
