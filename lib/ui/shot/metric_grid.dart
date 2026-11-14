import 'package:flutter/material.dart';

/// Formats a metric value with one decimal, or `--` when unknown.
String formatMetric(double? value) => value?.toStringAsFixed(1) ?? '--';

/// One metric: a large value with a small unit after it and an optional
/// label underneath. The unit is hidden when the value is unknown (`--`).
class MetricCell extends StatelessWidget {
  final String value;
  final String? unit;
  final String? label;
  final Color? valueColor;

  const MetricCell({
    super.key,
    required this.value,
    this.unit,
    this.label,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final unit = this.unit;
    final label = this.label;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text.rich(
          TextSpan(
            text: value,
            children: [
              if (unit != null && value != '--')
                TextSpan(
                  text: ' $unit',
                  style: theme.textTheme.bodyMedium?.copyWith(color: muted),
                ),
            ],
          ),
          style: theme.textTheme.titleLarge?.copyWith(
            color: valueColor,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (label != null) ...[
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(color: muted),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }
}

/// A single card holding metric cells in rows of [columns].
class MetricGrid extends StatelessWidget {
  final List<Widget> cells;
  final int columns;

  const MetricGrid({super.key, required this.cells, this.columns = 3});

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var start = 0; start < cells.length; start += columns) {
      if (rows.isNotEmpty) rows.add(const SizedBox(height: 16));
      rows.add(
        Row(
          children: [
            for (var i = start; i < start + columns; i++)
              Expanded(
                child: i < cells.length ? cells[i] : const SizedBox.shrink(),
              ),
          ],
        ),
      );
    }
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
        child: Column(mainAxisSize: MainAxisSize.min, children: rows),
      ),
    );
  }
}
