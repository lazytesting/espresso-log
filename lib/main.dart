// lib/main.dart
import 'dart:async';

import 'package:espresso_log/data/pressure/bookoo_pressure_service.dart';
import 'package:espresso_log/data/pressure/mock_pressure_service.dart';
import 'package:espresso_log/data/scale/decent_scale_service.dart';
import 'package:espresso_log/data/scale/mock_scale_service.dart';
import 'package:espresso_log/domain/shot/abstract_shot_clock.dart';
import 'package:espresso_log/domain/shot/auto_start_stop_rule.dart';
import 'package:espresso_log/domain/shot/auto_tare_rule.dart';
import 'package:espresso_log/domain/shot/shot_clock.dart';
import 'package:espresso_log/domain/telemetry/pressure_repository.dart';
import 'package:espresso_log/domain/telemetry/scale_repository.dart';

import 'package:espresso_log/router.dart';
import 'package:espresso_log/ui/theme.dart';

import 'package:espresso_log/ui/components/current-weight/current_weight_cubit.dart';
import 'package:espresso_log/ui/components/pressure/pressure_cubit.dart';
import 'package:espresso_log/ui/home/device_connection/connection_cubit.dart';
import 'package:espresso_log/ui/home/device_connection/connection_modal_wrapper.dart';
import 'package:espresso_log/ui/shot/timer/timer_cubit.dart';
import 'package:espresso_log/ui/components/weight-change/weight_change_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:idle_detector_wrapper/idle_detector_wrapper.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:talker_flutter/talker_flutter.dart';

import 'data/bluetooth/bluetooth_devices_service.dart';

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

  final AbstractShotClock shotClock = ShotClock();

  final scaleRepository = useMockScale
      ? MockScaleService()
      : DecentScaleService(bluetoothService, talker);

  final PressureRepository pressureRepository = useMockPressure
      ? MockPressureService()
      : BookooPressureService(bluetoothService, talker);

  final AbstractAutoTareRule autoTareRule = AutoTareRule(scaleRepository);
  final AbstractAutoStartStopRule autoStartStopRule = AutoStartStopRule(
    pressureRepository,
    shotClock,
  );
  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => CurrentWeightCubit(scaleRepository)),
        BlocProvider(create: (_) => WeightChangeCubit(scaleRepository)),
        BlocProvider(create: (_) => TimerCubit(shotClock)),
        BlocProvider(create: (_) => PressureCubit(pressureRepository)),
        BlocProvider(
          create: (_) =>
              ConnectionCubit(scaleRepository, pressureRepository)..connect(),
        ),
      ],
      child: MultiProvider(
        providers: [
          Provider<Talker>.value(value: talker),
          Provider<ScaleRepository>.value(value: scaleRepository),
          Provider<PressureRepository>.value(value: pressureRepository),
          Provider<AbstractShotClock>.value(value: shotClock),
          Provider<AbstractAutoTareRule>.value(value: autoTareRule),
          Provider<AbstractAutoStartStopRule>.value(value: autoStartStopRule),
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
          theme: buildAppTheme(),
          routerConfig: AppRouter(
            context.read<Talker>(),
            globalNavigatorKey,
          ).router,
        ),
      ),
    );
  }
}
