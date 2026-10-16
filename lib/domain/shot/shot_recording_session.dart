import 'package:espresso_log/domain/shot/median_filter.dart';
import 'package:espresso_log/domain/shot/shot_graph_point.dart';
import 'package:espresso_log/domain/shot/shot_metrics.dart';
import 'package:espresso_log/domain/shot/shot_snapshot.dart';
import 'package:espresso_log/domain/telemetry/pressure_reading.dart';
import 'package:espresso_log/domain/telemetry/weight_reading.dart';

/// Smooths raw weight readings to remove single-sample spikes, e.g. from
/// bumping the scale while pressing tare.
final _weightSmoothingFilter = MedianFilter(windowSize: 5);

/// Accumulates readings for a single shot.
///
/// A session is not started until [start] is called with the shot's start
/// time. Readings and tare events are ignored while not started, and once
/// started, ignored if timestamped before that start time — callers can
/// freely forward every reading/tare event without checking readiness
/// themselves. Create a new instance per shot rather than reusing one.
///
/// A shot has three phases: pouring (after [start]), dripping (after
/// [endPour], readings keep being recorded) and finished (after [stop], which
/// cuts off recording).
class ShotRecordingSession {
  DateTime? _startDateTime;
  DateTime? _pourEndDateTime;
  DateTime? _lastTickDateTime;
  DateTime? _endDateTime;
  DateTime? _tareDateTime;
  final List<WeightReading> _weightReadings = [];
  final List<PressureReading> _pressureReadings = [];

  bool get isStarted => _startDateTime != null;

  void start(DateTime startDateTime) {
    if (_startDateTime != null) return;
    _startDateTime = startDateTime;
  }

  /// Whether the pour has ended but the shot is not finished yet.
  bool get isDripping => _pourEndDateTime != null && _endDateTime == null;

  /// Advances the shot clock while pouring.
  void tick(DateTime now) {
    if (!isStarted || _pourEndDateTime != null) return;
    _lastTickDateTime = now;
  }

  /// Marks the end of the pour (shot clock stopped). Recording continues.
  void endPour(DateTime pourEndDateTime) {
    if (!isStarted || _pourEndDateTime != null) return;
    _pourEndDateTime = pourEndDateTime;
  }

  /// Finishes the shot: readings after [endDateTime] are ignored.
  void stop(DateTime endDateTime) {
    if (_endDateTime != null) return;
    _endDateTime = endDateTime;
  }

  void tare(DateTime tareDateTime) {
    if (!_isWithinSession(tareDateTime)) return;
    _tareDateTime = tareDateTime;
  }

  void addWeight(WeightReading reading) {
    if (!_isWithinSession(reading.timeStamp)) return;
    _weightReadings.add(reading);
  }

  void addPressure(PressureReading reading) {
    if (!_isWithinSession(reading.timeStamp)) return;
    _pressureReadings.add(reading);
  }

  bool _isWithinSession(DateTime timeStamp) {
    if (_startDateTime == null || timeStamp.isBefore(_startDateTime!)) {
      return false;
    }
    if (_endDateTime != null && timeStamp.isAfter(_endDateTime!)) {
      return false;
    }

    return true;
  }

  ShotSnapshot get snapshot {
    final startDateTime = _startDateTime;
    if (startDateTime == null) return ShotSnapshot.empty;

    final pressureData = _pressureReadings
        .where((reading) => _isWithinSession(reading.timeStamp))
        .map((reading) {
          return ShotGraphPoint(
            reading.timeStamp.difference(startDateTime).inMilliseconds,
            reading.pressure,
          );
        })
        .toList();

    final tareDateTime = _tareDateTime;

    final weightReadings = _weightReadings
        .where((reading) => _isWithinSession(reading.timeStamp))
        .toList();
    final smoothedWeights = _weightSmoothingFilter.apply(
      weightReadings.map((reading) => reading.weight).toList(),
    );

    final weightData = [
      for (final (i, reading) in weightReadings.indexed)
        if (tareDateTime == null || reading.timeStamp.isAfter(tareDateTime))
          ShotGraphPoint(
            reading.timeStamp.difference(startDateTime).inMilliseconds,
            smoothedWeights[i],
          )
        else
          ShotGraphPoint(
            reading.timeStamp.difference(startDateTime).inMilliseconds,
            0,
          ),
    ];

    return ShotSnapshot(
      weightData: weightData,
      pressureData: pressureData,
      metrics: _metrics(startDateTime, weightData, pressureData),
      summary: _summary(startDateTime, weightData, pressureData),
    );
  }

  int _pourMillis(DateTime startDateTime) {
    final pourEnd = _pourEndDateTime ?? _lastTickDateTime ?? startDateTime;
    return pourEnd.difference(startDateTime).inMilliseconds;
  }

  ShotMetrics _metrics(
    DateTime startDateTime,
    List<ShotGraphPoint> weightData,
    List<ShotGraphPoint> pressureData,
  ) {
    return ShotMetrics(
      weight: weightData.lastOrNull?.value,
      weightChangeRate: weightChangeRates(weightData).lastOrNull,
      pressure: pressureData.lastOrNull?.value,
      elapsedMillis: _pourMillis(startDateTime),
    );
  }

  ShotSummary _summary(
    DateTime startDateTime,
    List<ShotGraphPoint> weightData,
    List<ShotGraphPoint> pressureData,
  ) {
    return ShotSummary(
      finalWeight: weightData.lastOrNull?.value,
      peakWeightChangeRate: weightChangeRates(
        weightData,
      ).fold<double?>(null, (peak, r) => peak == null || r > peak ? r : peak),
      peakPressure: pressureData.fold<double?>(
        null,
        (peak, p) => peak == null || p.value > peak ? p.value : peak,
      ),
      durationMillis: _pourMillis(startDateTime),
    );
  }
}
