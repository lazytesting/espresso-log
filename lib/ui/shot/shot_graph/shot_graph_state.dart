// lib/ui/shot/shot_graph/shot_graph_state.dart
part of 'shot_graph_cubit.dart';

sealed class ShotGraphState {}

final class ShotGraphInitial extends ShotGraphState {}

final class ShotGraphWaiting extends ShotGraphState {}

final class ShotGraphRun extends ShotGraphState with EquatableMixin {
  final List<ShotGraphPoint> pressureData;
  final List<ShotGraphPoint> weightData;
  ShotGraphRun(this.pressureData, this.weightData);

  @override
  List<Object?> get props => [pressureData, weightData];
}

final class ShotGraphUpdating extends ShotGraphRun {
  ShotGraphUpdating(super.pressureData, super.weightData);
}

final class ShotGraphStopped extends ShotGraphRun {
  ShotGraphStopped(super.pressureData, super.weightData);

  /// Same window the live g/s widget uses.
  static const _rateWindowMillis = 600;

  double? get finalWeight => weightData.isEmpty ? null : weightData.last.value;

  double? get peakPressure => pressureData.isEmpty
      ? null
      : pressureData.map((p) => p.value).reduce((a, b) => a > b ? a : b);

  double? get peakWeightChangeRate {
    double? peak;
    var windowStart = 0;
    for (var i = 1; i < weightData.length; i++) {
      final current = weightData[i];
      while (current.millisecond - weightData[windowStart].millisecond >
          _rateWindowMillis) {
        windowStart++;
      }
      final first = weightData[windowStart];
      final duration = current.millisecond - first.millisecond;
      if (duration <= 0) continue;
      final rate = (current.value - first.value) / duration * 1000;
      if (peak == null || rate > peak) peak = rate;
    }
    return peak;
  }
}
