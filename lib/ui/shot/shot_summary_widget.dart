import 'package:espresso_log/ui/shot/shot_graph/shot_graph_cubit.dart';
import 'package:espresso_log/ui/shot/timer/timer_widget.dart';
import 'package:flutter/material.dart';

/// End-of-shot metrics, shown in place of the live metrics once the shot stops.
class ShotSummaryWidget extends StatelessWidget {
  final ShotGraphStopped shot;

  const ShotSummaryWidget(this.shot, {super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Expanded(child: _MetricCard(_format(shot.finalWeight), 'Grams')),
        Expanded(child: _MetricCard(_format(shot.peakWeightChangeRate), 'g/s')),
        Expanded(child: _MetricCard(_format(shot.peakPressure), 'Bar')),
        const Expanded(child: TimerWidget()),
      ],
    );
  }

  String _format(double? value) => value?.toStringAsFixed(1) ?? '--.-';
}

class _MetricCard extends StatelessWidget {
  final String value;
  final String unit;

  const _MetricCard(this.value, this.unit);

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.hardEdge,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(value, style: const TextStyle(fontSize: 25)),
            Text(unit),
          ],
        ),
      ),
    );
  }
}
