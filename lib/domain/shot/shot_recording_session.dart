import 'package:espresso_log/domain/shot/shot_graph_point.dart';
import 'package:espresso_log/domain/shot/shot_snapshot.dart';
import 'package:espresso_log/domain/telemetry/pressure_reading.dart';
import 'package:espresso_log/domain/telemetry/weight_reading.dart';

class ShotRecordingSession {
  DateTime? _startDateTime;
  DateTime? _tareDateTime;
  final List<WeightReading> _weightReadings = [];
  final List<PressureReading> _pressureReadings = [];

  bool get isStarted => _startDateTime != null;

  void start(DateTime startDateTime) {
    _startDateTime = startDateTime;
    _tareDateTime = null;
    _weightReadings.clear();
    _pressureReadings.clear();
  }

  /// Marks the session as no longer running by nulling the start time. Does
  /// NOT clear the accumulated readings or the tare timestamp (only [reset]
  /// does that) — this mirrors the legacy ShotGraphCubit, which never
  /// cleared its notification lists on stop, only on the next
  /// start()/restart().
  ///
  /// Important: once the start time is null, [snapshot] returns an empty
  /// result regardless of what's retained internally, so callers must read
  /// [snapshot] BEFORE calling [stop] if they need the final data — the
  /// retained state is not re-observable through this class's own API
  /// afterward.
  void stop() {
    _startDateTime = null;
  }

  void reset() {
    _startDateTime = null;
    _tareDateTime = null;
    _weightReadings.clear();
    _pressureReadings.clear();
  }

  void tare(DateTime tareDateTime) {
    _tareDateTime = tareDateTime;
  }

  void addWeight(WeightReading reading) {
    _weightReadings.add(reading);
  }

  void addPressure(PressureReading reading) {
    _pressureReadings.add(reading);
  }

  ShotSnapshot get snapshot {
    final startDateTime = _startDateTime;
    if (startDateTime == null) {
      return ShotSnapshot.empty;
    }

    final pressureData = _pressureReadings.map((reading) {
      return ShotGraphPoint(
        reading.timeStamp.difference(startDateTime).inMilliseconds,
        reading.pressure,
      );
    }).toList();

    final tareDateTime = _tareDateTime;
    final weightData = _weightReadings.map((reading) {
      if (tareDateTime == null || reading.timeStamp.isAfter(tareDateTime)) {
        return ShotGraphPoint(
          reading.timeStamp.difference(startDateTime).inMilliseconds,
          reading.weight,
        );
      }
      return ShotGraphPoint(
        reading.timeStamp.difference(startDateTime).inMilliseconds,
        0,
      );
    }).toList();

    return ShotSnapshot(weightData: weightData, pressureData: pressureData);
  }
}
