import 'package:espresso_log/ui/home/shot_graph/shot_graph_cubit.dart';
import 'package:espresso_log/ui/home/shot_graph/shot_graph_initial_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class ShotGraphWidget extends StatelessWidget {
  const ShotGraphWidget({super.key});

  @override
  Widget build(BuildContext context) {
    BlocListener<ShotGraphCubit, ShotGraphState>(listener: (context, state) {
      if (state is ShotGraphStopped) {
        final snackBar = SnackBar(
          content: const Text('Run finished'),
          backgroundColor: (Colors.black12),
          action: SnackBarAction(
            label: 'restart',
            onPressed: () {
              context.read<ShotGraphCubit>().start();
            },
          ),
        );

        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    });

    return BlocBuilder<ShotGraphCubit, ShotGraphState>(
      builder: (context, state) {
        if (state is ShotGraphInitial) {
          return const ShotGraphInitialWidget();
        }

        if (state is ShotGraphWaiting) {
          return const Text("waiting for shot...");
        }

        if (state is ShotGraphRun) {
          return _getShotGraph(state);
        }

        return const Text('Error! Unexpected state');
      },
    );
  }

  Widget _getShotGraph(ShotGraphRun shotGraphRun) {
    return Card(
        clipBehavior: Clip.hardEdge,
        child: SfCartesianChart(
            legend: const Legend(isVisible: true),
            primaryXAxis: const NumericAxis(
              title: AxisTitle(text: 'Seconds'),
              minimum: 0,
              maximum: 40,
            ),
            primaryYAxis: const NumericAxis(
              name: 'Grams',
              minimum: 0,
              maximum: 40,
            ),
            axes: const <ChartAxis>[
              NumericAxis(
                name: 'bar',
                opposedPosition: true,
                interval: 1,
                minimum: 0,
                maximum: 10,
              )
            ],
            series: <CartesianSeries>[
              LineSeries<ShotGraphData, double>(
                  name: 'Grams',
                  dataSource: shotGraphRun.weightData,
                  animationDuration: 0,
                  isVisibleInLegend: false,
                  xValueMapper: (ShotGraphData sgd, _) =>
                      (sgd.millisecond / 1000).roundToDouble(),
                  yValueMapper: (ShotGraphData sgd, _) => sgd.value),
              LineSeries<ShotGraphData, double>(
                  name: 'Bar',
                  dataSource: shotGraphRun.pressureData,
                  animationDuration: 0,
                  isVisibleInLegend: false,
                  xValueMapper: (ShotGraphData sgd, _) =>
                      (sgd.millisecond / 1000).roundToDouble(),
                  yValueMapper: (ShotGraphData sgd, _) => sgd.value,
                  yAxisName: 'bar'),
            ]));
  }
}
