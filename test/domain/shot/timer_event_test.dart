// test/domain/shot/timer_event_test.dart
import 'package:espresso_log/domain/shot/timer_event.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final timeStamp = DateTime(2026, 1, 1, 10, 0);

  test('TimerStarted serializes to json', () {
    final TimerEvent event = TimerStarted(timeStamp, 0);
    expect(event.toJson(), {
      'type': 'TimerStarted',
      'milliSeconds': 0,
      'timeStamp': timeStamp.toIso8601String(),
    });
  });

  test('TimerTicked serializes to json', () {
    final TimerEvent event = TimerTicked(timeStamp, 1500);
    expect(event.toJson(), {
      'type': 'TimerTicked',
      'milliSeconds': 1500,
      'timeStamp': timeStamp.toIso8601String(),
    });
  });

  test('TimerStopped serializes to json', () {
    final TimerEvent event = TimerStopped(timeStamp, 28000);
    expect(event.toJson(), {
      'type': 'TimerStopped',
      'milliSeconds': 28000,
      'timeStamp': timeStamp.toIso8601String(),
    });
  });
}
