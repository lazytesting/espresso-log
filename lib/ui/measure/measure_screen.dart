import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class MeasureScreen extends StatelessWidget {
  const MeasureScreen({super.key});

  Widget bottomTitleWidgets(double value, TitleMeta meta) {
    const style = TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 10,
    );

    var text = "${value.ceil()}";
    return SideTitleWidget(
      axisSide: meta.axisSide,
      child: Text(text, style: style),
    );
  }

  Widget leftTitleWidgets(double value, TitleMeta meta) {
    const style = TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 15,
    );
    var text = "${value.ceil()}g";
    return Text(text, style: style, textAlign: TextAlign.left);
  }

  final List<Color> gradientColors = const [
    Colors.cyan,
    Colors.blue,
  ];

  @override
  Widget build(BuildContext context) {
    List<FlSpot> points = [];
    points.add(const FlSpot(0, 0));
    points.add(const FlSpot(1, 0));
    points.add(const FlSpot(2, 0));
    points.add(const FlSpot(3, 0));
    points.add(const FlSpot(4, 1));
    points.add(const FlSpot(5, 3));
    points.add(const FlSpot(6, 5));
    points.add(const FlSpot(7, 5));
    points.add(const FlSpot(8, 10));
    return Scaffold(
        body: Center(
      child: Stack(children: [
        ElevatedButton(onPressed: () => {}, child: Text("test")),
        AspectRatio(
            aspectRatio: 2,
            child: LineChart(LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: true,
                horizontalInterval: 1,
                verticalInterval: 1,
                getDrawingHorizontalLine: (value) {
                  return const FlLine(
                    color: Colors.black12,
                    strokeWidth: 1,
                  );
                },
                getDrawingVerticalLine: (value) {
                  return const FlLine(
                    color: Colors.black12,
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
                    interval: 1,
                    getTitlesWidget: bottomTitleWidgets,
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 1,
                    getTitlesWidget: leftTitleWidgets,
                    reservedSize: 42,
                  ),
                ),
              ),
              borderData: FlBorderData(
                show: true,
                border: Border.all(color: const Color(0xff37434d)),
              ),
              minX: 0,
              minY: 0,
              lineBarsData: [
                LineChartBarData(
                  spots: points,
                  isCurved: false,
                  gradient: LinearGradient(
                    colors: gradientColors,
                  ),
                  barWidth: 5,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(
                    show: false,
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: gradientColors
                          .map((color) => color.withOpacity(0.2))
                          .toList(),
                    ),
                  ),
                ),
              ],
            ))),
      ]),
    ));

    // current weight
    // current flowrate
    // tare button
    // start button
    // graph
  }
}
