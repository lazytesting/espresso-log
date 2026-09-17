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

  /// Marks the session as no longer running, keeping accumulated readings
  /// intact so a final [snapshot] can still be read afterwards. Mirrors
  /// legacy ShotGraphCubit, which nulled _startDateTime on stop without
  /// clearing its notification lists.
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
