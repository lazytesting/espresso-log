// lib/ui/shot/shot_graph/shot_graph_widget.dart
import 'package:espresso_log/domain/shot/shot_graph_point.dart';
import 'package:espresso_log/ui/shot/shot_graph/shot_graph_cubit.dart';
import 'package:espresso_log/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

const _kWeightSeriesColor = kAccentColor;
const _kPressureSeriesColor = Color(0xFFE8D7B0);
const _kAxisLabelColor = Colors.white70;
const _kGridLineColor = Colors.white12;

class ShotGraphWidget extends StatelessWidget {
  const ShotGraphWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ShotGraphCubit, ShotGraphState>(
      builder: (context, state) {
        if (state is ShotGraphInitial || state is ShotGraphWaiting) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text("Waiting for shot to start..."),
              ],
            ),
          );
        }

        if (state is ShotGraphRun) {
          return ShotGraph(
            weightData: state.weightData,
            pressureData: state.pressureData,
          );
        }

        return const Text('Error! Unexpected state');
      },
    );
  }
}

/// Static chart of a shot's weight and pressure series.
class ShotGraph extends StatelessWidget {
  final List<ShotGraphPoint> weightData;
  final List<ShotGraphPoint> pressureData;

  const ShotGraph({
    super.key,
    required this.weightData,
    required this.pressureData,
  });

  @override
  Widget build(BuildContext context) {
    var maxWeight = weightData.fold(
      0.0,
      (value, element) => value > element.value ? value : element.value,
    );
    if (maxWeight < 40) {
      maxWeight = 40;
    }

    var maxPressure = pressureData.fold(
      0.0,
      (value, element) => value > element.value ? value : element.value,
    );
    if (maxPressure < 10) {
      maxPressure = 10;
    }

    var maxMillisPressure = pressureData.fold(
      0,
      (value, element) =>
          value > element.millisecond ? value : element.millisecond,
    );

    var maxMillisGrams = weightData.fold(
      0,
      (value, element) =>
          value > element.millisecond ? value : element.millisecond,
    );

    var maxMillis = maxMillisPressure > maxMillisGrams
        ? maxMillisPressure
        : maxMillisGrams;

    double maxSeconds = 35;
    if (maxMillis > 35000) {
      maxSeconds = ((maxMillis / 10000).ceil()) * 10;
    }

    const axisLabelStyle = TextStyle(color: _kAxisLabelColor);
    const axisTitleStyle = TextStyle(color: _kAxisLabelColor);

    return Card(
      clipBehavior: Clip.hardEdge,
      child: SfCartesianChart(
        plotAreaBorderColor: _kGridLineColor,
        backgroundColor: kSurfaceColor,
        legend: const Legend(isVisible: true, textStyle: axisLabelStyle),
        primaryXAxis: NumericAxis(
          title: const AxisTitle(text: 'Seconds', textStyle: axisTitleStyle),
          minimum: 0,
          maximum: maxSeconds,
          labelStyle: axisLabelStyle,
          majorGridLines: const MajorGridLines(color: _kGridLineColor),
          axisLine: const AxisLine(color: _kGridLineColor),
        ),
        primaryYAxis: NumericAxis(
          name: 'Grams',
          minimum: 0,
          maximum: maxWeight,
          labelStyle: axisLabelStyle,
          majorGridLines: const MajorGridLines(color: _kGridLineColor),
          axisLine: const AxisLine(color: _kGridLineColor),
        ),
        axes: <ChartAxis>[
          NumericAxis(
            name: 'bar',
            opposedPosition: true,
            interval: 1,
            minimum: 0,
            maximum: maxPressure,
            labelStyle: axisLabelStyle,
            majorGridLines: const MajorGridLines(width: 0),
            axisLine: const AxisLine(color: _kGridLineColor),
          ),
        ],
        series: <CartesianSeries>[
          SplineSeries<ShotGraphPoint, double>(
            name: 'Grams',
            color: _kWeightSeriesColor,
            width: 2,
            dataSource: weightData,
            animationDuration: 0,
            splineType: SplineType.monotonic,
            isVisibleInLegend: true,
            emptyPointSettings: const EmptyPointSettings(
              mode: EmptyPointMode.average,
            ),
            xValueMapper: (ShotGraphPoint sgd, _) => sgd.millisecond / 1000,
            yValueMapper: (ShotGraphPoint sgd, _) => sgd.value,
          ),
          SplineSeries<ShotGraphPoint, double>(
            name: 'Bar',
            color: _kPressureSeriesColor,
            width: 2,
            dataSource: pressureData,
            animationDuration: 0,
            isVisibleInLegend: true,
            splineType: SplineType.monotonic,
            emptyPointSettings: const EmptyPointSettings(
              mode: EmptyPointMode.average,
            ),
            xValueMapper: (ShotGraphPoint sgd, _) => sgd.millisecond / 1000,
            yValueMapper: (ShotGraphPoint sgd, _) => sgd.value,
            yAxisName: 'bar',
          ),
        ],
      ),
    );
  }
}
