import 'package:espresso_log/domain/bean/bean_repository.dart';
import 'package:espresso_log/domain/shot/shot_repository.dart';
import 'package:espresso_log/ui/history/history_cubit.dart';
import 'package:espresso_log/ui/history/history_format.dart';
import 'package:espresso_log/ui/history/shot_bean_labels.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

String formatShotDate(DateTime date) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${date.year}-${two(date.month)}-${two(date.day)} '
      '${two(date.hour)}:${two(date.minute)}';
}

class HistoryScreen extends StatelessWidget {
  final DateTime Function() now;

  const HistoryScreen({super.key, this.now = DateTime.now});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => HistoryCubit(
        context.read<ShotRepository>(),
        context.read<BeanRepository>(),
      )..load(),
      child: _ReloadWhenActive(
        child: Scaffold(
          appBar: AppBar(title: const Text('History')),
          body: BlocBuilder<HistoryCubit, List<HistoryEntry>?>(
            builder: (context, entries) {
              if (entries == null) {
                return const Center(child: CircularProgressIndicator());
              }
              if (entries.isEmpty) {
                return const Center(child: Text('No saved shots yet'));
              }
              final days = groupByDay(entries);
              final today = now();
              return RefreshIndicator(
                onRefresh: context.read<HistoryCubit>().load,
                child: ListView(
                  children: [
                    for (final day in days) ...[
                      _DayHeader(formatDayHeader(day.day, today)),
                      for (final entry in day.entries) _HistoryRow(entry),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// The shell keeps the History tab alive while another tab is shown, so a shot
/// saved in the meantime would not appear. Inactive tabs have tickers
/// disabled, so reload when that flips back to enabled.
class _ReloadWhenActive extends StatefulWidget {
  final Widget child;

  const _ReloadWhenActive({required this.child});

  @override
  State<_ReloadWhenActive> createState() => _ReloadWhenActiveState();
}

class _ReloadWhenActiveState extends State<_ReloadWhenActive> {
  bool? _wasActive;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final active = TickerMode.valuesOf(context).enabled;
    if (_wasActive == false && active) {
      context.read<HistoryCubit>().load();
    }
    _wasActive = active;
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _DayHeader extends StatelessWidget {
  final String label;

  const _DayHeader(this.label);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        label,
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.primary,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  final HistoryEntry entry;

  const _HistoryRow(this.entry);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final shot = entry.shot;
    final roaster = entry.bean?.roaster;
    final summary = shot.snapshot.summary;
    const tabular = [FontFeature.tabularFigures()];
    return InkWell(
      onTap: () => context.push('/history/${shot.id}'),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 64),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              SizedBox(
                width: 56,
                child: Text(
                  formatTime(shot.recordedAt),
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: muted,
                    fontFeatures: tabular,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      beanNameFor(shot, entry.bean),
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: entry.bean == null ? muted : null,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (roaster != null)
                      Text(
                        roaster,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: muted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatDoseYield(shot.doseGrams, summary.finalWeight),
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontFeatures: tabular,
                    ),
                  ),
                  Text(
                    formatShotSeconds(summary.durationMillis),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: muted,
                      fontFeatures: tabular,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
