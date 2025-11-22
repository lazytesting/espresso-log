import 'package:espresso_log/services/auto-start-stop/auto_start_stop_service.dart';
import 'package:espresso_log/services/auto-tare/auto_tare_service.dart';
import 'package:espresso_log/services/pressure/abstract_pressure_service.dart';
import 'package:espresso_log/services/pressure/bookoo_pressure_service.dart';
import 'package:espresso_log/services/pressure/mock_pressure_service.dart';
import 'package:espresso_log/services/scale/abstract_scale_service.dart';
import 'package:espresso_log/router.dart';
import 'package:espresso_log/services/scale/decent_scale_service.dart';
import 'package:espresso_log/services/scale/mock_scale_service.dart';
import 'package:espresso_log/services/timer/abstract_timer_service.dart';
import 'package:espresso_log/services/timer/timer_service.dart';
import 'package:espresso_log/ui/home/current-weight/current_weight_cubit.dart';
import 'package:espresso_log/ui/home/loader/loader_cubit.dart';
import 'package:espresso_log/ui/home/pressure/pressure_cubit.dart';
import 'package:espresso_log/ui/home/shot_graph/shot_graph_cubit.dart';
import 'package:espresso_log/ui/home/timer/timer_cubit.dart';
import 'package:espresso_log/ui/home/weight-change/weight_change_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:talker_flutter/talker_flutter.dart';

import 'services/bluetooth/bluetooth_service.dart';

const useMockScale = bool.fromEnvironment(
  'USE_MOCK_SCALE',
  defaultValue: false,
);
const useMockPressure = bool.fromEnvironment(
  'USE_MOCK_PRESSURE',
  defaultValue: false,
);

//final getIt = GetIt.instance;
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

  final pressureService = useMockPressure
      ? MockPressureService()
      : BookooPressureService(bluetoothService, talker);

  final AbstractAutoTareService autoTareService = AutoTareService(scaleService);
  final AbstractAutoStartStopService autoStartStopService =
      AutoStartStopService(pressureService, timerService);

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => ShotGraphCubit(
            autoStartStopService,
            scaleService,
            timerService,
            autoTareService,
            pressureService,
          ),
        ),
        BlocProvider(create: (_) => CurrentWeightCubit(scaleService)),
        BlocProvider(create: (_) => WeightChangeCubit(scaleService)),
        BlocProvider(create: (_) => TimerCubit(timerService)),
        BlocProvider(create: (_) => PressureCubit(pressureService)),
        BlocProvider(
          create: (_) => LoaderCubit(scaleService, pressureService)..load(),
        ),
      ],
      child: MultiProvider(
        providers: [
          Provider<Talker>.value(value: talker),
          Provider<AbstractScaleService>.value(value: scaleService),
          Provider<AbstractPressureService>.value(value: pressureService),
          Provider<AbstractTimerService>.value(value: timerService),
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
    return BlocBuilder<LoaderCubit, LoaderState>(
      builder: (context, state) {
        if (state is LoaderCompleted) {
          return MaterialApp.router(
            theme: ThemeData.from(
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color.fromARGB(255, 84, 48, 134),
              ),
            ),
            routerConfig: AppRouter(context.read<Talker>()).router,
          );
        } else {
          return const CircularProgressIndicator();
        }
      },
    );
  }
}
