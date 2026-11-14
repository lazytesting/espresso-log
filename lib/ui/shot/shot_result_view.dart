import 'package:espresso_log/domain/bean/bean.dart';
import 'package:espresso_log/domain/shot/brew_ratio.dart';
import 'package:espresso_log/domain/shot/shot_snapshot.dart';
import 'package:espresso_log/ui/beans/beans_screen.dart';
import 'package:espresso_log/ui/history/shot_bean_labels.dart';
import 'package:espresso_log/ui/shot/metric_grid.dart';
import 'package:espresso_log/ui/shot/shot_graph/shot_graph_widget.dart';
import 'package:flutter/material.dart';

/// A finished shot: bean, all metrics in one grid, and the graph. Shared by
/// the shot-done screen and the history detail screen.
class ShotResultView extends StatelessWidget {
  final ShotSnapshot snapshot;
  final Bean? bean;
  final double? doseGrams;

  const ShotResultView({
    super.key,
    required this.snapshot,
    required this.bean,
    required this.doseGrams,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bean = this.bean;
    final summary = snapshot.summary;
    final ratio = brewRatio(
      outputGrams: summary.finalWeight,
      doseGrams: doseGrams,
    );
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                bean?.name ?? unknownBeanLabel,
                style: theme.textTheme.titleLarge,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (bean != null)
                Text(
                  BeansScreen.subtitle(bean),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        MetricGrid(
          cells: [
            MetricCell(
              value: formatMetric(doseGrams),
              unit: 'g',
              label: 'Dose',
            ),
            MetricCell(
              value: formatMetric(summary.finalWeight),
              unit: 'g',
              label: 'Yield',
            ),
            MetricCell(
              value: formatBrewRatio(ratio),
              label: 'Ratio',
              valueColor: ratio == null ? null : theme.colorScheme.primary,
            ),
            MetricCell(
              value: (summary.durationMillis / 1000).toStringAsFixed(1),
              unit: 's',
              label: 'Time',
            ),
            MetricCell(
              value: formatMetric(summary.peakPressure),
              unit: 'bar',
              label: 'Peak pressure',
            ),
            MetricCell(
              value: formatMetric(summary.peakWeightChangeRate),
              unit: 'g/s',
              label: 'Peak flow',
            ),
          ],
        ),
        const SizedBox(height: 16),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: SizedBox(
              height: 300,
              child: ShotGraph(
                weightData: snapshot.weightData,
                pressureData: snapshot.pressureData,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
