import 'dart:async';
import 'package:espresso_log/data/mock/mock_shot_simulator.dart';
import 'package:espresso_log/domain/telemetry/battery_device_mixin.dart';
import 'package:espresso_log/domain/telemetry/pressure_reading.dart';
import 'package:espresso_log/domain/telemetry/pressure_repository.dart';
import 'package:rxdart/subjects.dart';

class MockPressureService
    with BatteryDeviceMixin
    implements PressureRepository {
  MockPressureService(this._simulator) {
    stream = _pressureReadingController.stream.asBroadcastStream();
  }
  final MockShotSimulator _simulator;
  final _pressureReadingController = BehaviorSubject<PressureReading>();
  StreamSubscription<double>? _subscription;

  @override
  Stream<PressureReading> stream = const Stream.empty();

  @override
  Future<void> init() async {
    _simulator.start();
    _subscription = _simulator.pressure.listen((pressure) {
      _pressureReadingController.add(PressureReading(pressure, DateTime.now()));
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
  }

  @override
  Future<void> disconnect() {
    return Future.delayed(Duration(seconds: 1));
  }

  @override
  Future<void> reconnect() {
    return Future.delayed(Duration(seconds: 1));
  }
}
