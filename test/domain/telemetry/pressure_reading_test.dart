import 'package:espresso_log/domain/telemetry/pressure_reading.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('PressureReading serializes to json', () {
    final timeStamp = DateTime(2026, 1, 1, 10, 0);
    final reading = PressureReading(8.4, timeStamp);

    expect(reading.toJson(), {
      'type': 'PressureReading',
      'pressure': 8.4,
      'timeStamp': timeStamp.toIso8601String(),
    });
  });
}
