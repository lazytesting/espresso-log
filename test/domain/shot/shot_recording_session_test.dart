import 'package:espresso_log/domain/shot/shot_recording_session.dart';
import 'package:espresso_log/domain/telemetry/pressure_reading.dart';
import 'package:espresso_log/domain/telemetry/weight_reading.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final t0 = DateTime(2026, 1, 1, 8, 0, 0);

  test('snapshot before start returns empty series', () {
    final session = ShotRecordingSession();

    expect(session.isStarted, isFalse);
    expect(session.snapshot.weightData, isEmpty);
    expect(session.snapshot.pressureData, isEmpty);
  });

  test('readings added before start are ignored', () {
    final session = ShotRecordingSession();

    session.addWeight(WeightReading(weight: 18, timeStamp: t0));
    session.addPressure(PressureReading(6.5, t0));
    session.tare(t0);

    expect(session.snapshot.weightData, isEmpty);
    expect(session.snapshot.pressureData, isEmpty);
  });

  test('weight is offset in milliseconds relative to the start time', () {
    final session = ShotRecordingSession()..start(t0);

    session.addWeight(
      WeightReading(
        weight: 18,
        timeStamp: t0.add(const Duration(milliseconds: 2500)),
      ),
    );

    expect(session.snapshot.weightData, [
      predicate<dynamic>((p) => p.millisecond == 2500 && p.value == 18),
    ]);
  });

  test('pressure is offset in milliseconds relative to the start time', () {
    final session = ShotRecordingSession()..start(t0);

    session.addPressure(
      PressureReading(6.5, t0.add(const Duration(milliseconds: 4000))),
    );

    expect(session.snapshot.pressureData, [
      predicate<dynamic>((p) => p.millisecond == 4000 && p.value == 6.5),
    ]);
  });

  test('weight readings before the tare timestamp are zeroed', () {
    final session = ShotRecordingSession()..start(t0);

    session.addWeight(
      WeightReading(
        weight: 5,
        timeStamp: t0.add(const Duration(milliseconds: 100)),
      ),
    );
    session.tare(t0.add(const Duration(milliseconds: 200)));
    session.addWeight(
      WeightReading(
        weight: 18,
        timeStamp: t0.add(const Duration(milliseconds: 300)),
      ),
    );

    final weightData = session.snapshot.weightData;
    expect(weightData[0].value, 0);
    expect(weightData[1].value, 18);
  });

  test('weight readings after the tare timestamp keep their real value', () {
    final session = ShotRecordingSession()..start(t0);

    session.tare(t0.add(const Duration(milliseconds: 100)));
    session.addWeight(
      WeightReading(
        weight: 24.3,
        timeStamp: t0.add(const Duration(milliseconds: 150)),
      ),
    );

    expect(session.snapshot.weightData.single.value, 24.3);
  });

  test('without a tare event no weight is zeroed', () {
    final session = ShotRecordingSession()..start(t0);

    session.addWeight(
      WeightReading(
        weight: 7,
        timeStamp: t0.add(const Duration(milliseconds: 50)),
      ),
    );

    expect(session.snapshot.weightData.single.value, 7);
  });

  test('a single-sample weight spike is smoothed out', () {
    final session = ShotRecordingSession()..start(t0);
    session.tare(t0);

    // A brief touch of the scale (e.g. while pressing tare) sends one wild
    // reading between otherwise-stable ones.
    for (final (offsetMs, weight) in [
      (100, 18.0),
      (200, 18.0),
      (300, 55.0),
      (400, 18.0),
      (500, 18.0),
    ]) {
      session.addWeight(
        WeightReading(
          weight: weight,
          timeStamp: t0.add(Duration(milliseconds: offsetMs)),
        ),
      );
    }

    final weightData = session.snapshot.weightData;
    expect(weightData.map((p) => p.value), everyElement(18.0));
  });

  test('weight readings before the start time are ignored', () {
    final session = ShotRecordingSession()..start(t0);

    session.addWeight(
      WeightReading(
        weight: 99,
        timeStamp: t0.subtract(const Duration(milliseconds: 1)),
      ),
    );

    expect(session.snapshot.weightData, isEmpty);
  });

  test('pressure readings before the start time are ignored', () {
    final session = ShotRecordingSession()..start(t0);

    session.addPressure(
      PressureReading(9, t0.subtract(const Duration(milliseconds: 1))),
    );

    expect(session.snapshot.pressureData, isEmpty);
  });

  test('a tare timestamp before the start time is ignored', () {
    final session = ShotRecordingSession()..start(t0);

    session.tare(t0.subtract(const Duration(milliseconds: 1)));
    session.addWeight(
      WeightReading(
        weight: 18,
        timeStamp: t0.add(const Duration(milliseconds: 100)),
      ),
    );

    expect(session.snapshot.weightData.single.value, 18);
  });

  test('weight readings after the end time are ignored', () {
    final session = ShotRecordingSession()..start(t0);
    session.stop(t0.add(const Duration(milliseconds: 500)));

    session.addWeight(
      WeightReading(
        weight: 18,
        timeStamp: t0.add(const Duration(milliseconds: 501)),
      ),
    );

    expect(session.snapshot.weightData, isEmpty);
  });

  test('pressure readings after the end time are ignored', () {
    final session = ShotRecordingSession()..start(t0);
    session.stop(t0.add(const Duration(milliseconds: 500)));

    session.addPressure(
      PressureReading(6.5, t0.add(const Duration(milliseconds: 501))),
    );

    expect(session.snapshot.pressureData, isEmpty);
  });

  test('a tare timestamp after the end time is ignored', () {
    final session = ShotRecordingSession()..start(t0);
    session.stop(t0.add(const Duration(milliseconds: 500)));

    session.addWeight(
      WeightReading(
        weight: 5,
        timeStamp: t0.add(const Duration(milliseconds: 100)),
      ),
    );
    session.tare(t0.add(const Duration(milliseconds: 501)));

    // the tare call itself is ignored (timestamp beyond the session), so the
    // earlier weight reading is never zeroed
    expect(session.snapshot.weightData.single.value, 5);
  });

  test('readings up to and including the end time are kept', () {
    final session = ShotRecordingSession()..start(t0);
    session.stop(t0.add(const Duration(milliseconds: 500)));

    session.addWeight(
      WeightReading(
        weight: 18,
        timeStamp: t0.add(const Duration(milliseconds: 500)),
      ),
    );

    expect(session.snapshot.weightData.single.value, 18);
  });

  test('calling stop twice keeps the first end time', () {
    final session = ShotRecordingSession()..start(t0);
    session.stop(t0.add(const Duration(milliseconds: 500)));
    session.stop(t0.add(const Duration(milliseconds: 5000)));

    session.addWeight(
      WeightReading(
        weight: 18,
        timeStamp: t0.add(const Duration(milliseconds: 600)),
      ),
    );

    expect(session.snapshot.weightData, isEmpty);
  });

  test('calling start twice keeps the first start time', () {
    final session = ShotRecordingSession()..start(t0);
    session.start(t0.add(const Duration(milliseconds: 1000)));

    session.addWeight(
      WeightReading(
        weight: 18,
        timeStamp: t0.add(const Duration(milliseconds: 100)),
      ),
    );

    expect(session.snapshot.weightData.single.millisecond, 100);
  });

  group('metrics and summary', () {
    WeightReading weightAt(int ms, double weight) => WeightReading(
      weight: weight,
      timeStamp: t0.add(Duration(milliseconds: ms)),
    );
    PressureReading pressureAt(int ms, double bar) =>
        PressureReading(bar, t0.add(Duration(milliseconds: ms)));

    // Weights are a step so the median smoothing leaves them unchanged.
    void addStepWeights(ShotRecordingSession session) {
      for (final (i, weight) in <double>[0, 0, 0, 5, 5, 5, 5].indexed) {
        session.addWeight(weightAt(i * 100, weight));
      }
    }

    test('live metrics follow the latest readings and clock tick', () {
      final session = ShotRecordingSession()..start(t0);
      addStepWeights(session);
      session.addPressure(pressureAt(200, 6));
      session.addPressure(pressureAt(400, 8));
      session.tick(t0.add(const Duration(milliseconds: 600)));

      final metrics = session.snapshot.metrics;
      expect(metrics.weight, 5);
      expect(metrics.pressure, 8);
      expect(metrics.elapsedMillis, 600);
      // 5 g over the last 600 ms
      expect(metrics.weightChangeRate, closeTo(5 / 0.6, 0.001));
    });

    test('summary has final weight, peak rate, peak pressure and duration', () {
      final session = ShotRecordingSession()..start(t0);
      addStepWeights(session);
      session.addPressure(pressureAt(100, 9));
      session.addPressure(pressureAt(500, 4));
      session.endPour(t0.add(const Duration(milliseconds: 600)));

      final summary = session.snapshot.summary;
      expect(summary.finalWeight, 5);
      expect(summary.peakPressure, 9);
      expect(summary.durationMillis, 600);
      // steepest right after the step: 5 g over 300 ms
      expect(summary.peakWeightChangeRate, closeTo(5 / 0.3, 0.001));
    });

    test('readings are still recorded while dripping, not after stop', () {
      final session = ShotRecordingSession()..start(t0);
      session.endPour(t0.add(const Duration(milliseconds: 1000)));
      expect(session.isDripping, isTrue);

      session.addWeight(weightAt(1500, 36));
      expect(session.snapshot.summary.finalWeight, 36);
      // the pour duration does not include the drip
      expect(session.snapshot.summary.durationMillis, 1000);

      session.stop(t0.add(const Duration(milliseconds: 2000)));
      expect(session.isDripping, isFalse);
      session.addWeight(weightAt(2500, 40));
      expect(session.snapshot.summary.finalWeight, 36);
    });

    test('ticks after the pour ended do not change the elapsed time', () {
      final session = ShotRecordingSession()..start(t0);
      session.endPour(t0.add(const Duration(milliseconds: 1000)));
      session.tick(t0.add(const Duration(milliseconds: 3000)));

      expect(session.snapshot.metrics.elapsedMillis, 1000);
    });

    test('metrics are empty before any reading', () {
      final session = ShotRecordingSession()..start(t0);

      expect(session.snapshot.metrics.weight, isNull);
      expect(session.snapshot.summary.peakPressure, isNull);
    });
  });

  group('start compensation', () {
    WeightReading weightAt(int ms, double weight) => WeightReading(
      weight: weight,
      timeStamp: t0.add(Duration(milliseconds: ms)),
    );

    test('start backdates the shot and keeps buffered readings', () {
      final session = ShotRecordingSession(
        startCompensation: const Duration(seconds: 5),
      );
      session.addWeight(weightAt(-6000, 1));
      session.addWeight(weightAt(-4000, 2));
      session.addPressure(
        PressureReading(3, t0.add(const Duration(seconds: -2))),
      );
      session.start(t0);

      final snapshot = session.snapshot;
      // 5s before t0 is the new start: the -6s reading is dropped
      expect(snapshot.weightData.single.millisecond, 1000);
      expect(snapshot.weightData.single.value, 2);
      expect(snapshot.pressureData.single.millisecond, 3000);
    });

    test('elapsed time includes the compensation', () {
      final session = ShotRecordingSession(
        startCompensation: const Duration(seconds: 5),
      )..start(t0);
      session.endPour(t0.add(const Duration(seconds: 25)));

      expect(session.snapshot.summary.durationMillis, 30000);
    });

    test('readings older than the compensation are pruned before start', () {
      final session = ShotRecordingSession(
        startCompensation: const Duration(seconds: 5),
      );
      session.addWeight(weightAt(-60000, 1));
      session.addWeight(weightAt(0, 2));
      session.start(t0);

      expect(session.snapshot.weightData.map((p) => p.value), [2]);
    });

    test('a tare inside the compensated period zeroes earlier readings', () {
      final session = ShotRecordingSession(
        startCompensation: const Duration(seconds: 5),
      );
      session.addWeight(weightAt(-4000, 200));
      session.addWeight(weightAt(-3500, 200));
      session.tare(t0.add(const Duration(seconds: -3)));
      for (final ms in [-2500, -2000, -1500]) {
        session.addWeight(weightAt(ms, 0.5));
      }
      session.start(t0);

      expect(session.snapshot.weightData.map((p) => p.value), [
        0,
        0,
        0.5,
        0.5,
        0.5,
      ]);
    });

    test('a tare before the compensated period is ignored', () {
      final session = ShotRecordingSession(
        startCompensation: const Duration(seconds: 5),
      );
      session.tare(t0.add(const Duration(seconds: -20)));
      session.addWeight(weightAt(-2000, 7));
      session.start(t0);

      expect(session.snapshot.weightData.single.value, 7);
    });
  });

  test('flattens a temporary weight peak, e.g. a cup placed before tare', () {
    final session = ShotRecordingSession()..start(t0);

    for (var i = 0; i < 30; i++) {
      final isPeak = i >= 5 && i < 20;
      session.addWeight(
        WeightReading(
          weight: isPeak ? 100 : 0,
          timeStamp: t0.add(Duration(milliseconds: i * 100)),
        ),
      );
    }

    final snapshot = session.snapshot;
    expect(snapshot.weightData.map((p) => p.value), everyElement(0));
    expect(snapshot.summary.peakWeightChangeRate, 0);
  });
}
