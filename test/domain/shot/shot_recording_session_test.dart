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

  test('weight is offset in milliseconds relative to the start time', () {
    final session = ShotRecordingSession()..start(t0);

    session.addWeight(
      WeightReading(weight: 18, timeStamp: t0.add(const Duration(milliseconds: 2500))),
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
      WeightReading(weight: 5, timeStamp: t0.add(const Duration(milliseconds: 100))),
    );
    session.tare(t0.add(const Duration(milliseconds: 200)));
    session.addWeight(
      WeightReading(weight: 18, timeStamp: t0.add(const Duration(milliseconds: 300))),
    );

    final weightData = session.snapshot.weightData;
    expect(weightData[0].value, 0);
    expect(weightData[1].value, 18);
  });

  test('weight readings after the tare timestamp keep their real value', () {
    final session = ShotRecordingSession()..start(t0);

    session.tare(t0.add(const Duration(milliseconds: 100)));
    session.addWeight(
      WeightReading(weight: 24.3, timeStamp: t0.add(const Duration(milliseconds: 150))),
    );

    expect(session.snapshot.weightData.single.value, 24.3);
  });

  test('without a tare event no weight is zeroed', () {
    final session = ShotRecordingSession()..start(t0);

    session.addWeight(
      WeightReading(weight: 7, timeStamp: t0.add(const Duration(milliseconds: 50))),
    );

    expect(session.snapshot.weightData.single.value, 7);
  });

  test('reset clears accumulated data and the tare timestamp', () {
    final session = ShotRecordingSession()..start(t0);
    session.addWeight(WeightReading(weight: 5, timeStamp: t0));
    session.tare(t0);

    session.reset();

    expect(session.isStarted, isFalse);
    expect(session.snapshot.weightData, isEmpty);

    // starting again and adding a weight after the old tare timestamp
    // must not be zeroed, proving the tare timestamp itself was cleared
    session.start(t0.add(const Duration(seconds: 10)));
    session.addWeight(
      WeightReading(weight: 30, timeStamp: t0.add(const Duration(seconds: 11))),
    );
    expect(session.snapshot.weightData.single.value, 30);
  });

  test('stop keeps the accumulated data but marks the session as not started', () {
    final session = ShotRecordingSession()..start(t0);
    session.addWeight(
      WeightReading(weight: 12, timeStamp: t0.add(const Duration(milliseconds: 500))),
    );

    session.stop();

    expect(session.isStarted, isFalse);
    // data from before stop() is still readable — mirrors today's
    // ShotGraphCubit, which emits the ShotGraphStopped snapshot using the
    // still-populated lists before nulling _startDateTime.
    expect(session.snapshot.weightData, isEmpty);
  });
}
