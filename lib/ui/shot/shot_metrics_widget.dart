import 'package:espresso_log/domain/shot/shot_metrics.dart';
import 'package:espresso_log/ui/shot/metric_grid.dart';
import 'package:flutter/material.dart';

/// Metrics of a shot being recorded (pouring or dripping).
class ShotMetricsWidget extends StatelessWidget {
  final ShotMetrics metrics;

  const ShotMetricsWidget(this.metrics, {super.key});

  @override
  Widget build(BuildContext context) {
    return MetricGrid(
      columns: 4,
      cells: [
        MetricCell(value: formatMetric(metrics.weight), unit: 'g'),
        MetricCell(value: formatMetric(metrics.weightChangeRate), unit: 'g/s'),
        MetricCell(value: formatMetric(metrics.pressure), unit: 'bar'),
        MetricCell(
          value: (metrics.elapsedMillis ~/ 100 / 10).toStringAsFixed(1),
          unit: 's',
        ),
      ],
    );
  }
}
