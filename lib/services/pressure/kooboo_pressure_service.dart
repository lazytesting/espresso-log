import 'dart:async';
import 'package:espresso_log/services/pressure/abstract_pressure_service.dart';
import 'package:espresso_log/services/pressure/pressure_notification.dart';
import 'package:rxdart/subjects.dart';

class KoobooPressureService implements AbstractPressureService {
  @override
  final pressureNotificationController =
      BehaviorSubject<PressureNotification>();
  Timer? _timer;

  @override
  Future<void> init() async {
    _timer = Timer.periodic(const Duration(milliseconds: 200), (Timer t) {
      double pressure = 0;
      var seconds = t.tick / 5;
      if (seconds <= 4) {
        pressure = seconds * 2;
      }

      if (seconds > 4 && seconds <= 10) {
        pressure = 8 - (seconds - 4);
      }

      if (seconds > 10 && seconds <= 15) {
        pressure = 2 + (seconds - 10);
      }

      if (seconds > 15 && pressure < 30) {
        pressure = 7;
      }

      if (seconds > 30) {
        pressure = 0;
      }

      pressureNotificationController
          .add(PressureNotification(pressure, DateTime.now()));
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
  }
}
