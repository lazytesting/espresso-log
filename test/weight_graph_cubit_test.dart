import 'package:bloc_test/bloc_test.dart';
import 'package:espresso_log/services/scale/abstract_scale_service.dart';
import 'package:espresso_log/services/scale/weight_notification.dart';
import 'package:espresso_log/services/timer/abstract_timer_service.dart';
import 'package:espresso_log/ui/home/weight-change/weight_change_cubit.dart';
import 'package:espresso_log/ui/home/weight_graph/weight_graph_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:rxdart/rxdart.dart';

class FakeTimerService extends Fake implements AbstractTimerService {
  @override
  final timerUpdates = BehaviorSubject<TimerEvent>();
}

class FakeScaleService extends Fake implements AbstractScaleService {
  @override
  final scaleNotificationController = BehaviorSubject<ScaleNotification>();
}

void main() {
  final getIt = GetIt.instance;
  late AbstractTimerService fakeTimerService;
  late AbstractScaleService fakeScaleService;

  setUp(() {
    fakeTimerService = FakeTimerService();
    fakeScaleService = FakeScaleService();

    // Fake class
    getIt.registerSingleton<AbstractTimerService>(fakeTimerService);
    getIt.registerSingleton<AbstractScaleService>(fakeScaleService);
  });

  // test("Should show graph based on serie of weightnotificatiosn", () {
  //   // Arrange
  //   final cubit = WeightGraphCubit();

  //   // Act
  //   fakeTimerService.timerUpdates.add(TimerStartedEvent(0));
  //   fakeScaleService.scaleNotificationController.add(WeightNotification(
  //       weight: 0,
  //       isStable: true,
  //       timeStamp: DateTime(2020, 10, 15, 10, 00, 00)));
  //   fakeTimerService.timerUpdates.add(TimerTickedEvent(100));
  //   fakeScaleService.scaleNotificationController.add(WeightNotification(
  //       weight: 2,
  //       isStable: true,
  //       timeStamp: DateTime(2020, 10, 15, 10, 00, 01)));
  //   fakeTimerService.timerUpdates.add(TimerTickedEvent(200));
  //   fakeScaleService.scaleNotificationController.add(WeightNotification(
  //       weight: 5,
  //       isStable: true,
  //       timeStamp: DateTime(2020, 10, 15, 10, 00, 02)));

  //   // Assert
  //   expectLater(cubit.stream, emitsInOrder(<int>[0, 1, 2, 3]));
  // });

  blocTest('CounterBloc emits [2] when increment is added twice',
      build: () => WeightGraphCubit(),
      act: (bloc) {
        fakeTimerService.timerUpdates.add(TimerStartedEvent(DateTime.now()));
        fakeScaleService.scaleNotificationController.add(WeightNotification(
            weight: 0,
            isStable: true,
            timeStamp: DateTime(2020, 10, 15, 10, 00, 00)));
      },
      expect: () => {
            const TypeMatcher<WeightGraphUpdating>()
                .having((wg) => wg.data, 'graph data', hasLength(1))
          });
}
