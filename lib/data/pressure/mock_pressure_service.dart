import 'dart:async';
import 'package:espresso_log/data/models/battery_device_mixin.dart';
import 'package:espresso_log/domain/telemetry/pressure_reading.dart';
import 'package:espresso_log/domain/telemetry/pressure_repository.dart';
import 'package:rxdart/subjects.dart';

class MockPressureService with BatteryDeviceMixin implements PressureRepository {
  MockPressureService() {
    stream = _pressureReadingController.stream.asBroadcastStream();
  }
  final _pressureReadingController = BehaviorSubject<PressureReading>();
  Timer? _timer;

  @override
  Stream<PressureReading> stream = const Stream.empty();

  @override
  Future<void> init() async {
    Future.delayed(Duration(seconds: 3));
    _timer = Timer.periodic(const Duration(milliseconds: 200), (Timer t) {
      double pressure = 0;
      var seconds = t.tick / 5;
      if (seconds > 10 && seconds <= 15) {
        pressure = seconds - 10;
      } else if (seconds > 15 && seconds <= 20) {
        pressure = 5 - (seconds - 15);
      } else if (seconds > 20 && seconds <= 350) {
        pressure = 8;
      }
      _pressureReadingController.asBroadcastStream();
      _pressureReadingController.add(PressureReading(pressure, DateTime.now()));
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
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
