import 'package:espresso_log/services/auto-tare/auto_tare_service.dart';
import 'package:espresso_log/services/scale/abstract_scale_service.dart';
import 'package:espresso_log/services/scale/weight_notification.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:rxdart/rxdart.dart';

@GenerateNiceMocks([MockSpec<AbstractScaleService>()])
import 'auto_tare_service_test.mocks.dart';

void main() {
  test('stable weight increase should trigger tare', () async {
    var fakeScaleService = MockAbstractScaleService();
    var controller = BehaviorSubject<ScaleNotification>();
    when(fakeScaleService.stream).thenAnswer((_) => controller);

    var autoTareService = AutoTareService(fakeScaleService);
    var startTime = DateTime(2020, 02, 03, 10, 11);

    // when
    autoTareService.start();
    controller.add(WeightNotification(weight: 10, timeStamp: startTime));
    controller.add(WeightNotification(
        weight: 62, timeStamp: startTime.add(const Duration(milliseconds: 1))));

    controller.add(WeightNotification(
        weight: 62,
        timeStamp: startTime.add(const Duration(milliseconds: 1002))));

    // then
    await untilCalled(fakeScaleService.tareCommand());
    verify(fakeScaleService.tareCommand()).called(1);
  });

  test('unstable weight should not trigger tare', () async {
    var fakeScaleService = MockAbstractScaleService();
    var controller = BehaviorSubject<ScaleNotification>();
    when(fakeScaleService.stream).thenAnswer((_) => controller);

    var autoTareService = AutoTareService(fakeScaleService);
    var startTime = DateTime(2020, 02, 03, 10, 11);

    // when
    autoTareService.start();
    controller.add(WeightNotification(weight: 10, timeStamp: startTime));
    controller.add(WeightNotification(
        weight: 62, timeStamp: startTime.add(const Duration(milliseconds: 1))));

    controller.add(WeightNotification(
        weight: 62.3,
        timeStamp: startTime.add(const Duration(milliseconds: 1002))));

    // then
    await pumpEventQueue();
    verifyNever(fakeScaleService.tareCommand());
  });

  test('stable weight for short period should not trigger tare', () async {
    var fakeScaleService = MockAbstractScaleService();
    var controller = BehaviorSubject<ScaleNotification>();
    when(fakeScaleService.stream).thenAnswer((_) => controller);

    var autoTareService = AutoTareService(fakeScaleService);
    var startTime = DateTime(2020, 02, 03, 10, 11);

    // when
    autoTareService.start();
    controller.add(WeightNotification(weight: 10, timeStamp: startTime));
    controller.add(WeightNotification(
        weight: 62, timeStamp: startTime.add(const Duration(milliseconds: 1))));

    controller.add(WeightNotification(
        weight: 62,
        timeStamp: startTime.add(const Duration(milliseconds: 101))));

    // then
    await pumpEventQueue();
    verifyNever(fakeScaleService.tareCommand());
  });

  test('stable low weight increase should not trigger tare', () async {
    var fakeScaleService = MockAbstractScaleService();
    var controller = BehaviorSubject<ScaleNotification>();
    when(fakeScaleService.stream).thenAnswer((_) => controller);

    var autoTareService = AutoTareService(fakeScaleService);
    var startTime = DateTime(2020, 02, 03, 10, 11);

    // when
    autoTareService.start();
    controller.add(WeightNotification(weight: 10, timeStamp: startTime));
    controller.add(WeightNotification(
        weight: 20, timeStamp: startTime.add(const Duration(milliseconds: 1))));

    controller.add(WeightNotification(
        weight: 20,
        timeStamp: startTime.add(const Duration(milliseconds: 2001))));

    // then
    await pumpEventQueue();
    verifyNever(fakeScaleService.tareCommand());
  });
}
