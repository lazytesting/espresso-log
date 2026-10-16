import 'package:espresso_log/domain/shot/shot_metrics.dart';
import 'package:flutter/material.dart';

/// Metrics of a shot being recorded (pouring or dripping).
class ShotMetricsWidget extends StatelessWidget {
  final ShotMetrics metrics;

  const ShotMetricsWidget(this.metrics, {super.key});

  @override
  Widget build(BuildContext context) {
    return _MetricsRow(
      weight: metrics.weight,
      weightChangeRate: metrics.weightChangeRate,
      pressure: metrics.pressure,
      millis: metrics.elapsedMillis,
    );
  }
}

/// End-of-shot metrics, shown once the shot is finished.
class ShotSummaryWidget extends StatelessWidget {
  final ShotSummary summary;

  const ShotSummaryWidget(this.summary, {super.key});

  @override
  Widget build(BuildContext context) {
    return _MetricsRow(
      weight: summary.finalWeight,
      weightChangeRate: summary.peakWeightChangeRate,
      pressure: summary.peakPressure,
      millis: summary.durationMillis,
    );
  }
}

class _MetricsRow extends StatelessWidget {
  final double? weight;
  final double? weightChangeRate;
  final double? pressure;
  final int millis;

  const _MetricsRow({
    required this.weight,
    required this.weightChangeRate,
    required this.pressure,
    required this.millis,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Expanded(child: _MetricCard(_format(weight), 'Grams')),
        Expanded(child: _MetricCard(_format(weightChangeRate), 'g/s')),
        Expanded(child: _MetricCard(_format(pressure), 'Bar')),
        Expanded(
          child: _MetricCard(
            (millis ~/ 100 / 10).toStringAsFixed(1),
            'Seconds',
          ),
        ),
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
