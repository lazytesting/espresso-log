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
import 'package:espresso_log/ui/shot/shot_result_view.dart';
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
            state is ShotGraphStopped ? 'Shot done' : 'Shot in progress',
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'New shot',
            onPressed: () {
              context.read<TimerCubit>().reset();
              context.read<ShotGraphCubit>().restart();
            },
          ),
          BlocBuilder<ShotGraphCubit, ShotGraphState>(
            builder: (context, state) => state is ShotGraphStopped
                ? SaveShotButton(state.snapshot)
                : const SizedBox.shrink(),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: BlocBuilder<ShotGraphCubit, ShotGraphState>(
        builder: (context, state) {
          if (state is ShotGraphStopped) {
            return BlocBuilder<BeansCubit, BeansState>(
              builder: (context, beans) => ShotResultView(
                snapshot: state.snapshot,
                bean: beans.selectedBean,
                doseGrams: beans.doseGrams,
              ),
            );
          }
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              children: [
                if (state is ShotGraphRun)
                  ShotMetricsWidget(state.metrics)
                else
                  const MetricGrid(
                    columns: 4,
                    cells: [
                      CurrentWeightWidget(),
                      WeightChangeWidget(),
                      PressureWidget(),
                      TimerWidget(),
                    ],
                  ),
                const SizedBox(height: 16),
                const Expanded(child: ShotGraphWidget()),
              ],
            ),
          );
        },
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

  @override
  void didUpdateWidget(SaveShotButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.snapshot, widget.snapshot)) _saved = false;
  }

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
    if (_saved) {
      return const IconButton(
        icon: Icon(Icons.check),
        tooltip: 'Saved',
        onPressed: null,
      );
    }
    return FilledButton(onPressed: _save, child: const Text('Save'));
  }
}
