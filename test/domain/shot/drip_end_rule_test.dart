import 'package:espresso_log/domain/shot/abstract_shot_clock.dart';
import 'package:espresso_log/domain/shot/drip_end_rule.dart';
import 'package:espresso_log/domain/shot/timer_event.dart';
import 'package:espresso_log/domain/telemetry/scale_event.dart';
import 'package:espresso_log/domain/telemetry/scale_repository.dart';
import 'package:espresso_log/domain/telemetry/weight_reading.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:rxdart/rxdart.dart';

@GenerateNiceMocks([MockSpec<ScaleRepository>(), MockSpec<AbstractShotClock>()])
import 'drip_end_rule_test.mocks.dart';

void main() {
  late PublishSubject<ScaleEvent> scale;
  late PublishSubject<TimerEvent> clock;
  var ended = 0;

  late FakeAsync fake;

  // Stream deliveries are microtasks: flush them so events land immediately.
  void addWeight(double weight) {
    scale.add(WeightReading(weight: weight, timeStamp: DateTime(2020)));
    fake.flushMicrotasks();
  }

  void addClockEvent(TimerEvent event) {
    clock.add(event);
    fake.flushMicrotasks();
  }

  void stopClock() => addClockEvent(TimerStopped(DateTime(2020), 30000));

  // Everything is created inside fakeAsync so that stream deliveries and
  // timers run on the fake clock.
  void test_(String name, void Function(FakeAsync async) body) {
    test(name, () {
      fakeAsync((async) {
        fake = async;
        ended = 0;
        scale = PublishSubject<ScaleEvent>();
        clock = PublishSubject<TimerEvent>();
        final scaleRepository = MockScaleRepository();
        when(scaleRepository.stream).thenAnswer((_) => scale);
        final shotClock = MockAbstractShotClock();
        when(shotClock.stream).thenAnswer((_) => clock);
        DripEndRule(scaleRepository, shotClock).stream.listen((_) => ended++);
        body(async);
      });
    });
  }

  test_('ends after 1s without added weight', (async) {
    stopClock();
    addWeight(40);
    async.elapse(const Duration(milliseconds: 900));
    expect(ended, 0);
    async.elapse(const Duration(milliseconds: 200));
    expect(ended, 1);
  });

  test_('does nothing before the clock stops', (async) {
    addWeight(40);
    async.elapse(const Duration(seconds: 6));
    expect(ended, 0);
  });

  test_('added weight restarts the settle timer', (async) {
    stopClock();
    addWeight(40);
    async.elapse(const Duration(milliseconds: 800));
    addWeight(40.5);
    async.elapse(const Duration(milliseconds: 800));
    expect(ended, 0);
    async.elapse(const Duration(milliseconds: 300));
    expect(ended, 1);
  });

  test_('ends at 5s max while weight keeps increasing', (async) {
    stopClock();
    var weight = 40.0;
    for (var i = 0; i < 20; i++) {
      addWeight(weight += 0.5);
      async.elapse(const Duration(milliseconds: 300));
    }
    expect(ended, 1);
  });

  test_('a new shot starting cancels the drip phase', (async) {
    stopClock();
    addClockEvent(TimerStarted(DateTime(2020), 0));
    async.elapse(const Duration(seconds: 6));
    expect(ended, 0);
  });
}
