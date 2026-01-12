import 'package:espresso_log/devices/pressure/models/abstract_pressure_service.dart';
import 'package:espresso_log/devices/scale/models/abstract_scale_service.dart';
import 'package:espresso_log/devices/timer/abstract_timer_service.dart';
import 'package:espresso_log/services/auto_start_stop_service.dart';
import 'package:espresso_log/services/auto_tare_service.dart';
import 'package:espresso_log/ui/components/current-weight/current_weight_widget.dart';
import 'package:espresso_log/ui/components/pressure/pressure_widget.dart';
import 'package:espresso_log/ui/shot/shot_cubit.dart';
import 'package:espresso_log/ui/shot/shot_graph_widget.dart';
import 'package:espresso_log/ui/shot/timer/timer_widget.dart';
import 'package:espresso_log/ui/components/weight-change/weight_change_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class ShotScreen extends StatelessWidget {
  const ShotScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ShotCubit(
        context.read<AbstractAutoStartStopService>(),
        context.read<AbstractScaleService>(),
        context.read<AbstractTimerService>(),
        context.read<AbstractAutoTareService>(),
        context.read<AbstractPressureService>(),
      )..start(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Shot In Progress'),
          actions: [
            IconButton(
              icon: Icon(Icons.refresh),
              onPressed: () {
                context.pushReplacement('/shot');
              },
            ),
          ],
        ),
        body: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(child: CurrentWeightWidget()),
                Expanded(child: WeightChangeWidget()),
                Expanded(child: PressureWidget()),
                Expanded(child: TimerWidget()),
              ],
            ),
            Expanded(child: ShotGraphWidget()),
          ],
        ),
      ),
    );
  }
}
