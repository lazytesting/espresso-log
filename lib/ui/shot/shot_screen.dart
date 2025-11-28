import 'package:espresso_log/ui/components/current-weight/current_weight_widget.dart';
import 'package:espresso_log/ui/components/pressure/pressure_widget.dart';
import 'package:espresso_log/ui/shot/shot_graph/shot_graph_cubit.dart';
import 'package:espresso_log/ui/shot/shot_graph/shot_graph_widget.dart';
import 'package:espresso_log/ui/shot/timer/timer_widget.dart';
import 'package:espresso_log/ui/components/weight-change/weight_change_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ShotScreen extends StatelessWidget {
  const ShotScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shot In Progress'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              context.read<ShotGraphCubit>().restart();
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
    );
  }
}
