import 'package:espresso_log/domain/telemetry/scale_event.dart';
import 'package:espresso_log/domain/telemetry/tare_event.dart';
import 'package:espresso_log/domain/telemetry/weight_reading.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('WeightReading and TareEvent serialize their distinguishing fields', () {
    final timeStamp = DateTime(2026, 1, 1, 10, 0);
    final ScaleEvent weightReading = WeightReading(
      weight: 42.5,
      timeStamp: timeStamp,
    );
    final ScaleEvent tareEvent = TareEvent(timeStamp: timeStamp);

    expect(weightReading.toJson(), {
      'type': 'WeightReading',
      'weight': 42.5,
      'timeStamp': timeStamp.toIso8601String(),
    });
    expect(tareEvent.toJson(), {
      'type': 'TareEvent',
      'timeStamp': timeStamp.toIso8601String(),
    });
  });
}
