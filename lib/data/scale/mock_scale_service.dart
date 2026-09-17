import 'dart:async';
import 'dart:math';

import 'package:espresso_log/domain/telemetry/scale_event.dart';
import 'package:espresso_log/domain/telemetry/scale_repository.dart';
import 'package:espresso_log/domain/telemetry/tare_event.dart';
import 'package:espresso_log/domain/telemetry/weight_reading.dart';
import 'package:rxdart/rxdart.dart';

class MockScaleService implements ScaleRepository {
  final _scaleEventController = BehaviorSubject<ScaleEvent>();
  Timer? _timer;
  int _count = 0;
  @override
  Stream<ScaleEvent> stream = const Stream.empty();

  MockScaleService() {
    stream = _scaleEventController.stream.asBroadcastStream();
  }

  @override
  Future<void> init() async {
    _timer = Timer.periodic(const Duration(milliseconds: 200), (Timer t) {
      var weight = (_count / 5) + Random().nextDouble();
      if (t.tick >= 40 && t.tick <= 55) {
        weight = 52;
      }

      _scaleEventController.add(
        WeightReading(weight: weight, timeStamp: DateTime.now()),
      );
      _count++;
    });
  }

  @override
  Future<void> tareCommand() async {
    _scaleEventController.add(TareEvent(timeStamp: DateTime.now()));
    _count = 0;
  }

  void dispose() {
    _timer?.cancel();
  }
}
