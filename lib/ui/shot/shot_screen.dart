import 'package:espresso_log/domain/shot/recorded_shot.dart';
import 'package:espresso_log/domain/shot/shot_repository.dart';
import 'package:espresso_log/domain/shot/shot_snapshot.dart';
import 'package:espresso_log/ui/beans/beans_cubit.dart';
import 'package:espresso_log/ui/components/current-weight/current_weight_widget.dart';
import 'package:espresso_log/ui/components/pressure/pressure_widget.dart';
import 'package:espresso_log/ui/shot/shot_graph/shot_graph_cubit.dart';
import 'package:espresso_log/ui/shot/shot_graph/shot_graph_widget.dart';
import 'package:espresso_log/ui/shot/metric_grid.dart';
import 'package:espresso_log/ui/shot/shot_metrics_widget.dart';
import 'package:espresso_log/ui/shot/timer/timer_cubit.dart';
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
        title: BlocBuilder<ShotGraphCubit, ShotGraphState>(
          builder: (context, state) => Text(
            state is ShotGraphStopped ? 'Shot Done' : 'Shot In Progress',
          ),
        ),
        actions: [
          BlocBuilder<ShotGraphCubit, ShotGraphState>(
            builder: (context, state) => state is ShotGraphStopped
                ? SaveShotButton(state.snapshot)
                : const SizedBox.shrink(),
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              context.read<TimerCubit>().reset();
              context.read<ShotGraphCubit>().restart();
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          children: [
            BlocBuilder<ShotGraphCubit, ShotGraphState>(
              builder: (context, state) {
                if (state is ShotGraphRun) {
                  return ShotMetricsWidget(state.metrics);
                }
                return const MetricGrid(
                  columns: 4,
                  cells: [
                    CurrentWeightWidget(),
                    WeightChangeWidget(),
                    PressureWidget(),
                    TimerWidget(),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            Expanded(child: ShotGraphWidget()),
          ],
        ),
      ),
    );
  }
}

class SaveShotButton extends StatefulWidget {
  final ShotSnapshot snapshot;

  const SaveShotButton(this.snapshot, {super.key});

  @override
  State<SaveShotButton> createState() => _SaveShotButtonState();
}

class _SaveShotButtonState extends State<SaveShotButton> {
  bool _saved = false;

  Future<void> _save() async {
    final repository = context.read<ShotRepository>();
    final messenger = ScaffoldMessenger.of(context);
    final beans = context.read<BeansCubit>().state;
    await repository.save(
      RecordedShot.create(
        widget.snapshot,
        beanId: beans.selectedBeanId,
        doseGrams: beans.doseGrams,
      ),
    );
    if (!mounted) return;
    setState(() => _saved = true);
    messenger.showSnackBar(const SnackBar(content: Text('Shot saved')));
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(_saved ? Icons.check : Icons.save_alt),
      tooltip: 'Save shot',
      onPressed: _saved ? null : _save,
    );
  }
}
