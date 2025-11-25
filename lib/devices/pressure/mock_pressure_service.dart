import 'dart:async';
import 'package:espresso_log/devices/pressure/models/abstract_pressure_service.dart';
import 'package:espresso_log/devices/pressure/models/pressure_notification.dart';
import 'package:rxdart/subjects.dart';

class MockPressureService implements AbstractPressureService {
  MockPressureService() {
    stream = _pressureNotificationController.stream.asBroadcastStream();
  }
  final _pressureNotificationController =
      BehaviorSubject<PressureNotification>();
  Timer? _timer;

  @override
  Stream<PressureNotification> stream = const Stream.empty();

  @override
  Future<void> init() async {
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
      _pressureNotificationController.asBroadcastStream();
      _pressureNotificationController.add(
        PressureNotification(pressure, DateTime.now()),
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
  }
}
