import 'package:espresso_log/domain/telemetry/scale_event.dart';
import 'package:espresso_log/domain/telemetry/tare_event.dart';
import 'package:espresso_log/domain/telemetry/weight_reading.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('WeightReading serializes to json with its weight', () {
    final timeStamp = DateTime(2026, 1, 1, 10, 0);
    final ScaleEvent event = WeightReading(weight: 42.5, timeStamp: timeStamp);

    expect(event.toJson(), {
      'type': 'WeightReading',
      'weight': 42.5,
      'timeStamp': timeStamp.toIso8601String(),
    });
  });

  test('TareEvent serializes to json without a weight field', () {
    final timeStamp = DateTime(2026, 1, 1, 10, 0, 5);
    final ScaleEvent event = TareEvent(timeStamp: timeStamp);

    expect(event.toJson(), {
      'type': 'TareEvent',
      'timeStamp': timeStamp.toIso8601String(),
    });
  });

  test('both event types are assignable to the shared ScaleEvent type', () {
    final List<ScaleEvent> events = [
      WeightReading(weight: 1, timeStamp: DateTime(2026)),
      TareEvent(timeStamp: DateTime(2026)),
    ];

    expect(events, hasLength(2));
  });
}
