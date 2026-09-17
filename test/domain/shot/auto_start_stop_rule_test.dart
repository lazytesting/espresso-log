import 'package:espresso_log/domain/shot/abstract_shot_clock.dart';
import 'package:espresso_log/domain/shot/auto_start_stop_rule.dart';
import 'package:espresso_log/domain/shot/timer_event.dart';
import 'package:espresso_log/domain/telemetry/pressure_reading.dart';
import 'package:espresso_log/domain/telemetry/pressure_repository.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:rxdart/rxdart.dart';

@GenerateNiceMocks([MockSpec<PressureRepository>()])
import 'auto_start_stop_rule_test.mocks.dart';

/// A fake shot clock that actually tracks running state, since the rule's
/// decisions depend on reading [isRunning] back after calling start()/stop().
class FakeShotClock implements AbstractShotClock {
  bool _isRunning = false;
  int startCalls = 0;
  int stopCalls = 0;

  @override
  Stream<TimerEvent> stream = const Stream.empty();

  @override
  bool get isRunning => _isRunning;

  @override
  Future<void> start() async {
    _isRunning = true;
    startCalls++;
  }

  @override
  Future<void> stop() async {
    _isRunning = false;
    stopCalls++;
  }
}

void main() {
  late MockPressureRepository fakePressureRepository;
  late BehaviorSubject<PressureReading> controller;
  late FakeShotClock shotClock;
  final t0 = DateTime(2020, 02, 03, 10, 11);

  setUp(() {
    fakePressureRepository = MockPressureRepository();
    controller = BehaviorSubject<PressureReading>();
    when(fakePressureRepository.stream).thenAnswer((_) => controller);
    shotClock = FakeShotClock();
  });

  test('disabled rule ignores pressure and never starts the clock', () async {
    AutoStartStopRule(fakePressureRepository, shotClock);

    controller.add(PressureReading(5, t0));
    await pumpEventQueue();

    expect(shotClock.startCalls, 0);
  });

  test('pressure crossing threshold1 starts the clock once enabled', () async {
    final rule = AutoStartStopRule(fakePressureRepository, shotClock);
    rule.enable();

    controller.add(PressureReading(0.2, t0));
    await pumpEventQueue();

    expect(shotClock.startCalls, 1);
    expect(shotClock.isRunning, isTrue);
  });

  test(
    'pressure below threshold2 does not stop the clock, even if it dips',
    () async {
      final rule = AutoStartStopRule(fakePressureRepository, shotClock);
      rule.enable();

      controller.add(PressureReading(0.2, t0)); // starts
      controller.add(
        PressureReading(0.3, t0.add(const Duration(milliseconds: 1))),
      );
      controller.add(
        PressureReading(0.05, t0.add(const Duration(milliseconds: 2))),
      );
      await pumpEventQueue();

      expect(shotClock.stopCalls, 0);
      expect(shotClock.isRunning, isTrue);
    },
  );

  test(
    'pressure reaching threshold2 and then dropping below it stops the clock',
    () async {
      final rule = AutoStartStopRule(fakePressureRepository, shotClock);
      rule.enable();

      controller.add(PressureReading(0.2, t0)); // starts
      controller.add(
        PressureReading(0.6, t0.add(const Duration(milliseconds: 1))),
      ); // reaches threshold2
      controller.add(
        PressureReading(0.3, t0.add(const Duration(milliseconds: 2))),
      ); // drops below threshold2
      await pumpEventQueue();

      expect(shotClock.stopCalls, 1);
      expect(shotClock.isRunning, isFalse);
    },
  );

  test(
    'after auto-stopping, the rule disables itself and ignores further readings',
    () async {
      final rule = AutoStartStopRule(fakePressureRepository, shotClock);
      rule.enable();

      controller.add(PressureReading(0.2, t0));
      controller.add(
        PressureReading(0.6, t0.add(const Duration(milliseconds: 1))),
      );
      controller.add(
        PressureReading(0.3, t0.add(const Duration(milliseconds: 2))),
      ); // auto-stops and disables
      controller.add(
        PressureReading(0.2, t0.add(const Duration(milliseconds: 3))),
      ); // should be ignored: rule disabled itself
      await pumpEventQueue();

      expect(shotClock.startCalls, 1);
      expect(shotClock.stopCalls, 1);
    },
  );

  test(
    'disable() pauses the subscription so pressure readings are ignored',
    () async {
      final rule = AutoStartStopRule(fakePressureRepository, shotClock);
      rule.enable();
      rule.disable();

      controller.add(PressureReading(0.2, t0));
      await pumpEventQueue();

      expect(shotClock.startCalls, 0);
    },
  );

  test('enable() after disable() resumes reacting to pressure', () async {
    final rule = AutoStartStopRule(fakePressureRepository, shotClock);
    rule.enable();
    rule.disable();
    rule.enable();

    controller.add(PressureReading(0.2, t0));
    await pumpEventQueue();

    expect(shotClock.startCalls, 1);
  });
}
