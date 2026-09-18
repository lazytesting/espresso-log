// lib/domain/shot/auto_start_stop_rule.dart
import 'package:espresso_log/domain/shot/abstract_shot_clock.dart';
import 'package:espresso_log/domain/telemetry/pressure_repository.dart';

abstract class AbstractAutoStartStopRule {
  void enable();
  void disable();
}

class AutoStartStopRule implements AbstractAutoStartStopRule {
  bool _enabled = false;
  final double _treshold1 = 0.1;
  final double _treshold2 = 0.5;
  bool _treshold2Reached = false;

  AutoStartStopRule(
    PressureRepository pressureRepository,
    AbstractShotClock shotClock,
  ) {
    pressureRepository.stream.listen((reading) {
      if (!_enabled) {
        return;
      }

      // start
      if (!shotClock.isRunning && reading.pressure > _treshold1) {
        shotClock.start();
        return;
      }

      // treshold2 reached
      if (shotClock.isRunning && reading.pressure >= _treshold2) {
        _treshold2Reached = true;
        return;
      }

      // below treshold2
      if (shotClock.isRunning &&
          _treshold2Reached &&
          reading.pressure < _treshold2) {
        disable();
        shotClock.stop();
      }
    });
  }

  @override
  void enable() {
    _treshold2Reached = false;
    _enabled = true;
  }

  @override
  void disable() {
    _treshold2Reached = false;
    _enabled = false;
  }
}
