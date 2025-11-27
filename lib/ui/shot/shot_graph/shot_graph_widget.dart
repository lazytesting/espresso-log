import 'package:espresso_log/ui/shot/shot_graph/shot_graph_cubit.dart';
import 'package:espresso_log/ui/shot/shot_graph/shot_graph_initial_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class ShotGraphWidget extends StatelessWidget {
  const ShotGraphWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ShotGraphCubit, ShotGraphState>(
      listener: (context, state) {
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
      },
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
    var maxWeight = shotGraphRun.weightData.fold(
      0.0,
      (value, element) => value > element.value ? value : element.value,
    );
    if (maxWeight < 40) {
      maxWeight = 40;
    }

    var maxPressure = shotGraphRun.pressureData.fold(
      0.0,
      (value, element) => value > element.value ? value : element.value,
    );
    if (maxPressure < 10) {
      maxPressure = 10;
    }

    var maxMillisPressure = shotGraphRun.pressureData.fold(
      0,
      (value, element) =>
          value > element.millisecond ? value : element.millisecond,
    );

    var maxMillisGrams = shotGraphRun.weightData.fold(
      0,
      (value, element) =>
          value > element.millisecond ? value : element.millisecond,
    );

    var maxMillis = maxMillisPressure > maxMillisGrams
        ? maxMillisPressure
        : maxMillisGrams;

    double maxSeconds = 40;
    if (maxMillis > 40000) {
      maxSeconds = ((maxMillis / 10000).ceil()) * 10;
    }

    return Card(
      clipBehavior: Clip.hardEdge,
      child: SfCartesianChart(
        legend: const Legend(isVisible: true),
        primaryXAxis: NumericAxis(
          title: const AxisTitle(text: 'Seconds'),
          minimum: 0,
          maximum: maxSeconds,
        ),
        primaryYAxis: NumericAxis(
          name: 'Grams',
          minimum: 0,
          maximum: maxWeight,
        ),
        axes: <ChartAxis>[
          NumericAxis(
            name: 'bar',
            opposedPosition: true,
            interval: 1,
            minimum: 0,
            maximum: maxPressure,
          ),
        ],
        series: <CartesianSeries>[
          SplineSeries<ShotGraphData, double>(
            name: 'Grams',
            dataSource: shotGraphRun.weightData,
            animationDuration: 0,
            splineType: SplineType.natural,
            isVisibleInLegend: true,
            emptyPointSettings: const EmptyPointSettings(
              mode: EmptyPointMode.average,
            ),
            xValueMapper: (ShotGraphData sgd, _) =>
                (sgd.millisecond / 1000).roundToDouble(),
            yValueMapper: (ShotGraphData sgd, _) => sgd.value,
          ),
          SplineSeries<ShotGraphData, double>(
            name: 'Bar',
            dataSource: shotGraphRun.pressureData,
            animationDuration: 0,
            isVisibleInLegend: true,
            splineType: SplineType.natural,
            emptyPointSettings: const EmptyPointSettings(
              mode: EmptyPointMode.average,
            ),
            xValueMapper: (ShotGraphData sgd, _) =>
                (sgd.millisecond / 1000).roundToDouble(),
            yValueMapper: (ShotGraphData sgd, _) => sgd.value,
            yAxisName: 'bar',
          ),
        ],
      ),
    );
  }
}
