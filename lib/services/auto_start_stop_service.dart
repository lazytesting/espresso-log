import 'package:espresso_log/devices/pressure/models/abstract_pressure_service.dart';
import 'package:espresso_log/devices/timer/abstract_timer_service.dart';

abstract class AbstractAutoStartStopService {
  void enable();
}

class AutoStartStopService implements AbstractAutoStartStopService {
  bool _enabled = false;
  final double _treshold1 = 0.1;
  final double _treshold2 = 0.5;
  bool _treshold2Reached = false;

  AutoStartStopService(
    AbstractPressureService pressureService,
    AbstractTimerService timerService,
  ) {
    pressureService.stream.listen((notification) {
      if (!_enabled) {
        return;
      }

      // start
      if (!timerService.isRunning && notification.pressure > _treshold1) {
        timerService.start();
        return;
      }

      // treshold2 reached
      if (timerService.isRunning && notification.pressure >= _treshold2) {
        _treshold2Reached = true;
        return;
      }

      // below treshold2
      if (timerService.isRunning &&
          _treshold2Reached &&
          notification.pressure < _treshold2) {
        _enabled = false;
        timerService.stop();
      }
    });
  }

  @override
  void enable() {
    //temp
    _enabled = true;
  }
}
