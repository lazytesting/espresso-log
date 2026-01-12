import 'dart:async';

import 'package:espresso_log/devices/pressure/bookoo_pressure_service.dart';
import 'package:espresso_log/devices/pressure/mock_pressure_service.dart';
import 'package:espresso_log/devices/pressure/models/abstract_pressure_service.dart';
import 'package:espresso_log/devices/scale/decent_scale_service.dart';
import 'package:espresso_log/devices/scale/mock_scale_service.dart';
import 'package:espresso_log/devices/scale/models/abstract_scale_service.dart';
import 'package:espresso_log/devices/timer/abstract_timer_service.dart';
import 'package:espresso_log/devices/timer/timer_service.dart';
import 'package:espresso_log/services/auto_start_stop_service.dart';
import 'package:espresso_log/services/auto_tare_service.dart';

import 'package:espresso_log/router.dart';

import 'package:espresso_log/ui/components/current-weight/current_weight_cubit.dart';
import 'package:espresso_log/ui/components/pressure/pressure_cubit.dart';
import 'package:espresso_log/ui/home/device_connection/connection_cubit.dart';
import 'package:espresso_log/ui/home/device_connection/connection_modal_wrapper.dart';
import 'package:espresso_log/ui/components/weight-change/weight_change_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:idle_detector_wrapper/idle_detector_wrapper.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:talker_flutter/talker_flutter.dart';

import 'devices/bluetooth/bluetooth_service.dart';

const useMockScale = bool.fromEnvironment(
  'USE_MOCK_SCALE',
  defaultValue: false,
);
const useMockPressure = bool.fromEnvironment(
  'USE_MOCK_PRESSURE',
  defaultValue: false,
);

final GlobalKey<NavigatorState> globalNavigatorKey =
    GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  WakelockPlus.enable();

  final Talker talker = TalkerFlutter.init();
  final BluetoothDevicesService bluetoothService = BluetoothDevicesService(
    talker: talker,
  );
  await bluetoothService.init();

  final AbstractTimerService timerService = TimerService();

  final scaleService = useMockScale
      ? MockScaleService()
      : DecentScaleService(bluetoothService, talker);

  final AbstractPressureService pressureService = useMockPressure
      ? MockPressureService()
      : BookooPressureService(bluetoothService, talker);

  final AbstractAutoTareService autoTareService = AutoTareService(scaleService);
  final AbstractAutoStartStopService autoStartStopService =
      AutoStartStopService(pressureService, timerService);
  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => CurrentWeightCubit(scaleService)),
        BlocProvider(create: (_) => WeightChangeCubit(scaleService)),
        BlocProvider(create: (_) => PressureCubit(pressureService)),
        BlocProvider(
          create: (_) =>
              ConnectionCubit(scaleService, pressureService)..connect(),
        ),
      ],
      child: MultiProvider(
        providers: [
          Provider<Talker>.value(value: talker),
          Provider<AbstractScaleService>.value(value: scaleService),
          Provider<AbstractPressureService>.value(value: pressureService),
          Provider<AbstractTimerService>.value(value: timerService),
          Provider<AbstractAutoStartStopService>.value(
            value: autoStartStopService,
          ),
          Provider<AbstractAutoTareService>.value(value: autoTareService),
        ],
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return IdleDetector(
      idleTime: const Duration(minutes: 5),
      onIdle: () {
        unawaited(context.read<ConnectionCubit>().disconnect());
      },
      onActive: () {
        unawaited(context.read<ConnectionCubit>().reconnect());
      },
      child: ConnectionModalWrapper(
        navigatorKey: globalNavigatorKey,
        child: MaterialApp.router(
          theme:
              ThemeData.from(
                colorScheme: ColorScheme.fromSeed(
                  seedColor: const Color.fromARGB(255, 84, 48, 134),
                ),
              ).copyWith(
                appBarTheme: const AppBarTheme(
                  backgroundColor: Color.fromARGB(255, 88, 77, 105),
                  foregroundColor: Colors.white,
                ),
              ),
          routerConfig: AppRouter(
            context.read<Talker>(),
            globalNavigatorKey,
          ).router,
        ),
      ),
    );
  }
}
