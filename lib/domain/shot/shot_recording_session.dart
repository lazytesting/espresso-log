import 'package:espresso_log/domain/shot/median_filter.dart';
import 'package:espresso_log/domain/shot/shot_graph_point.dart';
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
class ShotRecordingSession {
  DateTime? _startDateTime;
  DateTime? _endDateTime;
  DateTime? _tareDateTime;
  final List<WeightReading> _weightReadings = [];
  final List<PressureReading> _pressureReadings = [];

  bool get isStarted => _startDateTime != null;

  void start(DateTime startDateTime) {
    if (_startDateTime != null) return;
    _startDateTime = startDateTime;
  }

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

    return ShotSnapshot(weightData: weightData, pressureData: pressureData);
  }
}
