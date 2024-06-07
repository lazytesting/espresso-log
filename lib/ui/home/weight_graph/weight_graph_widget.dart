import 'package:espresso_log/ui/home/timer/timer_cubit.dart';
import 'package:espresso_log/ui/home/weight_graph/weight_graph_cubit.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class WeightGraphWidget extends StatelessWidget {
  const WeightGraphWidget({super.key});

  Widget _bottomTitleWidgets(double value, TitleMeta meta) {
    const style = TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 2,
    );
    var text = Text((value / 1000).round().toString());

    return SideTitleWidget(
      axisSide: meta.axisSide,
      child: text,
    );
  }

  Widget _leftTitleWidgets(double value, TitleMeta meta) {
    const style = TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 15,
    );

    return Text(value.round().toString(),
        style: style, textAlign: TextAlign.left);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WeightGraphCubit, WeightGraphState>(
      builder: (context, state) {
        List<GraphData> data = [];
        if (state is WeightGraphUpdating) {
          data = state.data;
        }
        if (state is WeightGraphStopped) {
          data = state.data;
        }
        var spots = data
            .map((d) => FlSpot(d.millisecond.toDouble(), d.weight))
            .toList();

        var maxX = data.isNotEmpty ? data.last.millisecond : 10000;
        var maxY = data.isNotEmpty
            ? data
                .reduce((curr, next) => curr.weight > next.weight ? curr : next)
                .weight
            : 40;

        return Center(
            child: Card(
          clipBehavior: Clip.hardEdge,
          child: AspectRatio(
            aspectRatio: 1.70,
            child: Padding(
              padding: EdgeInsets.all(8.0),
              child: LineChart(LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  horizontalInterval: 5,
                  verticalInterval: 5000,
                  getDrawingHorizontalLine: (value) {
                    return const FlLine(
                      color: Colors.grey,
                      strokeWidth: 1,
                    );
                  },
                  getDrawingVerticalLine: (value) {
                    return const FlLine(
                      color: Colors.grey,
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 5000,
                      getTitlesWidget: _bottomTitleWidgets,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 5,
                      getTitlesWidget: _leftTitleWidgets,
                      reservedSize: 40,
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: false,
                  border: Border.all(color: const Color(0xff37434d)),
                ),
                minX: 0,
                maxX: maxX.toDouble(),
                minY: 0,
                maxY: maxY.toDouble(),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: Colors.purple,
                    barWidth: 5,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(
                      show: false,
                    ),
                  ),
                ],
              )),
            ),
          ),
        ));
      },
    );
  }
}
