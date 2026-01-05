import 'package:espresso_log/features/shot/shot_cubit.dart';
import 'package:espresso_log/features/shot/shot_graph_widget.dart';
import 'package:espresso_log/ui/metric_card_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ShotScreen extends StatelessWidget {
  const ShotScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Call start() after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ShotGraphCubit>().start();
    });

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
      body: BlocBuilder<ShotGraphCubit, ShotGraphState>(
        builder: (context, state) {
          String? timer;
          String? weightChange;
          String? currentWeight;
          String? currentPressure;
          if (state is ShotGraphRun) {
            timer = state.timer.toStringAsFixed(1);
            weightChange = state.weightChangeRate.toStringAsFixed(1);
            currentWeight = state.currentWeight.toStringAsFixed(1);
            currentPressure = state.currentPressure.toStringAsFixed(1);
          }

          return Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: MetricsCardWidget(
                      typeText: "Gram",
                      value: currentWeight,
                    ),
                  ),
                  Expanded(
                    child: MetricsCardWidget(
                      typeText: "g/s",
                      value: weightChange,
                    ),
                  ),
                  Expanded(
                    child: MetricsCardWidget(
                      typeText: "Bar",
                      value: currentPressure,
                    ),
                  ),
                  Expanded(
                    child: MetricsCardWidget(typeText: "Sec.", value: timer),
                  ),
                ],
              ),
              Expanded(
                child: ShotGraphWidget(state: state)
              ),
            ],
          );
        },
      ),
    );
  }
}
