import 'dart:async';

import 'package:espresso_log/data/mock/mock_shot_simulator.dart';
import 'package:espresso_log/domain/telemetry/scale_event.dart';
import 'package:espresso_log/domain/telemetry/scale_repository.dart';
import 'package:espresso_log/domain/telemetry/tare_event.dart';
import 'package:espresso_log/domain/telemetry/weight_reading.dart';
import 'package:rxdart/rxdart.dart';

class MockScaleService implements ScaleRepository {
  final MockShotSimulator _simulator;
  final _scaleEventController = BehaviorSubject<ScaleEvent>();
  StreamSubscription<double>? _subscription;
  double _tareOffset = 0;
  @override
  Stream<ScaleEvent> stream = const Stream.empty();

  MockScaleService(this._simulator) {
    stream = _scaleEventController.stream.asBroadcastStream();
  }

  @override
  Future<void> init() async {
    _simulator.start();
    _subscription = _simulator.rawWeight.listen((raw) {
      _scaleEventController.add(
        WeightReading(weight: raw - _tareOffset, timeStamp: DateTime.now()),
      );
    });
  }

  @override
  Future<void> tareCommand() async {
    _tareOffset = _simulator.currentRawWeight;
    _scaleEventController.add(TareEvent(timeStamp: DateTime.now()));
  }

  void dispose() {
    _subscription?.cancel();
  }
}
