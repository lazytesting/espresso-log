import 'package:equatable/equatable.dart';
import 'package:espresso_log/domain/shot/shot_graph_point.dart';

/// Window over which the weight change rate (g/s) is measured.
const _rateWindowMillis = 600;

/// The weight change rate (g/s) at every point, measured over the preceding
/// [_rateWindowMillis]. The first point has no history, so its rate is 0.
List<double> weightChangeRates(List<ShotGraphPoint> weightData) {
  final rates = <double>[];
  var windowStart = 0;
  for (var i = 0; i < weightData.length; i++) {
    final current = weightData[i];
    while (current.millisecond - weightData[windowStart].millisecond >
        _rateWindowMillis) {
      windowStart++;
    }
    final first = weightData[windowStart];
    final duration = current.millisecond - first.millisecond;
    rates.add(
      duration <= 0 ? 0 : (current.value - first.value) / duration * 1000,
    );
  }
  return rates;
}

/// Metrics of a shot while it is being recorded.
class ShotMetrics extends Equatable {
  final double? weight;
  final double? weightChangeRate;
  final double? pressure;
  final int elapsedMillis;

  const ShotMetrics({
    this.weight,
    this.weightChangeRate,
    this.pressure,
    this.elapsedMillis = 0,
  });

  static const empty = ShotMetrics();

  @override
  List<Object?> get props => [
    weight,
    weightChangeRate,
    pressure,
    elapsedMillis,
  ];
}

/// End-of-shot metrics.
class ShotSummary extends Equatable {
  final double? finalWeight;
  final double? peakWeightChangeRate;
  final double? peakPressure;

  /// Duration of the pour: from the shot start until the shot clock stopped.
  final int durationMillis;

  const ShotSummary({
    this.finalWeight,
    this.peakWeightChangeRate,
    this.peakPressure,
    this.durationMillis = 0,
  });

  static const empty = ShotSummary();

  @override
  List<Object?> get props => [
    finalWeight,
    peakWeightChangeRate,
    peakPressure,
    durationMillis,
  ];
}
