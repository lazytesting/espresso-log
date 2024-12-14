import 'package:espresso_log/ui/home/current-weight/current_weight_widget.dart';
import 'package:espresso_log/ui/home/pressure/pressure_widget.dart';
import 'package:espresso_log/ui/home/shot_graph/shot_graph_widget.dart';
import 'package:espresso_log/ui/home/timer/timer_widget.dart';
import 'package:espresso_log/ui/home/weight-change/weight_change_widget.dart';
import 'package:espresso_log/ui/home/weight_graph/weight_graph_widget.dart';
import 'package:espresso_log/ui/scaffold/screen_container.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ScreenContainer(
        title: 'Home',
        child: Column(children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(child: CurrentWeightWidget()),
              Expanded(child: WeightChangeWidget()),
              Expanded(child: PressureWidget()),
              Expanded(child: TimerWidget()),
            ],
          ),
          Expanded(child: ShotGraphWidget())
        ]));
  }
}
