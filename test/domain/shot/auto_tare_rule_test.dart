import 'package:espresso_log/domain/shot/auto_tare_rule.dart';
import 'package:espresso_log/domain/telemetry/scale_event.dart';
import 'package:espresso_log/domain/telemetry/scale_repository.dart';
import 'package:espresso_log/domain/telemetry/weight_reading.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:rxdart/rxdart.dart';

@GenerateNiceMocks([MockSpec<ScaleRepository>()])
import 'auto_tare_rule_test.mocks.dart';

void main() {
  test('stable weight increase should trigger tare', () async {
    var fakeScaleRepository = MockScaleRepository();
    var controller = BehaviorSubject<ScaleEvent>();
    when(fakeScaleRepository.stream).thenAnswer((_) => controller);

    var autoTareRule = AutoTareRule(fakeScaleRepository);
    var startTime = DateTime(2020, 02, 03, 10, 11);

    // when
    autoTareRule.enable();
    controller.add(WeightReading(weight: 10, timeStamp: startTime));
    controller.add(
      WeightReading(
        weight: 62,
        timeStamp: startTime.add(const Duration(milliseconds: 1)),
      ),
    );

    controller.add(
      WeightReading(
        weight: 62,
        timeStamp: startTime.add(const Duration(milliseconds: 1002)),
      ),
    );

    // then
    await untilCalled(fakeScaleRepository.tareCommand());
    verify(fakeScaleRepository.tareCommand()).called(1);
  });

  test('unstable weight should not trigger tare', () async {
    var fakeScaleRepository = MockScaleRepository();
    var controller = BehaviorSubject<ScaleEvent>();
    when(fakeScaleRepository.stream).thenAnswer((_) => controller);

    var autoTareRule = AutoTareRule(fakeScaleRepository);
    var startTime = DateTime(2020, 02, 03, 10, 11);

    // when
    autoTareRule.enable();
    controller.add(WeightReading(weight: 10, timeStamp: startTime));
    controller.add(
      WeightReading(
        weight: 62,
        timeStamp: startTime.add(const Duration(milliseconds: 1)),
      ),
    );

    controller.add(
      WeightReading(
        weight: 62.3,
        timeStamp: startTime.add(const Duration(milliseconds: 1002)),
      ),
    );

    // then
    await pumpEventQueue();
    verifyNever(fakeScaleRepository.tareCommand());
  });

  test('stable weight for short period should not trigger tare', () async {
    var fakeScaleRepository = MockScaleRepository();
    var controller = BehaviorSubject<ScaleEvent>();
    when(fakeScaleRepository.stream).thenAnswer((_) => controller);

    var autoTareRule = AutoTareRule(fakeScaleRepository);
    var startTime = DateTime(2020, 02, 03, 10, 11);

    // when
    autoTareRule.enable();
    controller.add(WeightReading(weight: 10, timeStamp: startTime));
    controller.add(
      WeightReading(
        weight: 62,
        timeStamp: startTime.add(const Duration(milliseconds: 1)),
      ),
    );

    controller.add(
      WeightReading(
        weight: 62,
        timeStamp: startTime.add(const Duration(milliseconds: 101)),
      ),
    );

    // then
    await pumpEventQueue();
    verifyNever(fakeScaleRepository.tareCommand());
  });

  test('stable low weight increase should not trigger tare', () async {
    var fakeScaleRepository = MockScaleRepository();
    var controller = BehaviorSubject<ScaleEvent>();
    when(fakeScaleRepository.stream).thenAnswer((_) => controller);

    var autoTareRule = AutoTareRule(fakeScaleRepository);
    var startTime = DateTime(2020, 02, 03, 10, 11);

    // when
    autoTareRule.enable();
    controller.add(WeightReading(weight: 10, timeStamp: startTime));
    controller.add(
      WeightReading(
        weight: 20,
        timeStamp: startTime.add(const Duration(milliseconds: 1)),
      ),
    );

    controller.add(
      WeightReading(
        weight: 20,
        timeStamp: startTime.add(const Duration(milliseconds: 2001)),
      ),
    );

    // then
    await pumpEventQueue();
    verifyNever(fakeScaleRepository.tareCommand());
  });

  test(
    'a stable weight does not trigger a second tare after the first',
    () async {
      var fakeScaleRepository = MockScaleRepository();
      var controller = BehaviorSubject<ScaleEvent>();
      when(fakeScaleRepository.stream).thenAnswer((_) => controller);

      var autoTareRule = AutoTareRule(fakeScaleRepository);
      var startTime = DateTime(2020, 02, 03, 10, 11);

      autoTareRule.enable();
      controller.add(WeightReading(weight: 10, timeStamp: startTime));
      controller.add(
        WeightReading(
          weight: 62,
          timeStamp: startTime.add(const Duration(milliseconds: 1)),
        ),
      );
      controller.add(
        WeightReading(
          weight: 62,
          timeStamp: startTime.add(const Duration(milliseconds: 1002)),
        ),
      );
      await untilCalled(fakeScaleRepository.tareCommand());

      // the rule stops itself after tare fires, so further stable weight
      // should not trigger another tare
      controller.add(
        WeightReading(
          weight: 62,
          timeStamp: startTime.add(const Duration(milliseconds: 2500)),
        ),
      );
      await pumpEventQueue();

      verify(fakeScaleRepository.tareCommand()).called(1);
    },
  );

  test(
    'disable() stops reacting so further readings are ignored',
    () async {
      var fakeScaleRepository = MockScaleRepository();
      var controller = BehaviorSubject<ScaleEvent>();
      when(fakeScaleRepository.stream).thenAnswer((_) => controller);

      var autoTareRule = AutoTareRule(fakeScaleRepository);
      var startTime = DateTime(2020, 02, 03, 10, 11);

      autoTareRule.enable();
      controller.add(WeightReading(weight: 10, timeStamp: startTime));
      autoTareRule.disable();

      controller.add(
        WeightReading(
          weight: 62,
          timeStamp: startTime.add(const Duration(milliseconds: 1)),
        ),
      );
      controller.add(
        WeightReading(
          weight: 62,
          timeStamp: startTime.add(const Duration(milliseconds: 1002)),
        ),
      );

      await pumpEventQueue();
      verifyNever(fakeScaleRepository.tareCommand());
    },
  );

  test(
    're-enabling after a tare (without an explicit disable() first) starts '
    'a clean shot instead of carrying over the previous shot\'s history, as '
    'happens when the UI simply calls enable() again for a second shot',
    () async {
      var fakeScaleRepository = MockScaleRepository();
      var controller = BehaviorSubject<ScaleEvent>();
      when(fakeScaleRepository.stream).thenAnswer((_) => controller);

      var autoTareRule = AutoTareRule(fakeScaleRepository);
      var startTime = DateTime(2020, 02, 03, 10, 11);

      // First shot: cup placed, stable weight tares.
      autoTareRule.enable();
      controller.add(WeightReading(weight: 10, timeStamp: startTime));
      controller.add(
        WeightReading(
          weight: 62,
          timeStamp: startTime.add(const Duration(milliseconds: 1)),
        ),
      );
      controller.add(
        WeightReading(
          weight: 62,
          timeStamp: startTime.add(const Duration(milliseconds: 1002)),
        ),
      );
      await untilCalled(fakeScaleRepository.tareCommand());

      // Second shot: UI re-enables directly (this is what ShotGraphCubit's
      // start()/restart() does), without ever calling disable() first.
      autoTareRule.enable();

      final secondShotStart = startTime.add(const Duration(seconds: 5));
      controller.add(WeightReading(weight: 5, timeStamp: secondShotStart));
      controller.add(
        WeightReading(
          weight: 57,
          timeStamp: secondShotStart.add(const Duration(milliseconds: 1)),
        ),
      );
      controller.add(
        WeightReading(
          weight: 57,
          timeStamp: secondShotStart.add(const Duration(milliseconds: 1002)),
        ),
      );
      await pumpEventQueue();

      verify(fakeScaleRepository.tareCommand()).called(2);
    },
  );
}
