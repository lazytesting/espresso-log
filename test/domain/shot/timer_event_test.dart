// test/domain/shot/timer_event_test.dart
import 'package:espresso_log/domain/shot/timer_event.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final timeStamp = DateTime(2026, 1, 1, 10, 0);

  test('each TimerEvent subtype serializes its type and milliSeconds', () {
    final events = <TimerEvent>[
      TimerStarted(timeStamp, 0),
      TimerTicked(timeStamp, 1500),
      TimerStopped(timeStamp, 28000),
    ];

    expect(events.map((e) => e.toJson()['type']), [
      'TimerStarted',
      'TimerTicked',
      'TimerStopped',
    ]);
    expect(events.map((e) => e.toJson()['milliSeconds']), [0, 1500, 28000]);
  });
}
