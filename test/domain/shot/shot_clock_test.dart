import 'package:espresso_log/domain/shot/shot_clock.dart';
import 'package:espresso_log/domain/shot/timer_event.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('isRunning is false before start and true after', () async {
    final clock = ShotClock();
    expect(clock.isRunning, isFalse);

    await clock.start();
    expect(clock.isRunning, isTrue);

    await clock.stop();
    expect(clock.isRunning, isFalse);
  });

  test('start emits a TimerStarted event with 0 milliseconds', () async {
    final clock = ShotClock();
    final events = <TimerEvent>[];
    clock.stream.listen(events.add);

    await clock.start();
    await pumpEventQueue();
    await clock.stop();

    expect(events.first, isA<TimerStarted>());
    expect(events.first.milliSeconds, 0);
  });

  test('stop emits a TimerStopped event', () async {
    final clock = ShotClock();
    final events = <TimerEvent>[];
    clock.stream.listen(events.add);

    await clock.start();
    await pumpEventQueue();
    await clock.stop();
    await pumpEventQueue();

    expect(events.last, isA<TimerStopped>());
  });
}
