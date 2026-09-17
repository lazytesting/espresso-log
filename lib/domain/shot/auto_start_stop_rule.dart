// lib/domain/shot/auto_start_stop_rule.dart
import 'dart:async';

import 'package:espresso_log/domain/shot/abstract_shot_clock.dart';
import 'package:espresso_log/domain/telemetry/pressure_reading.dart';
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
  StreamSubscription<PressureReading>? _pressureSubscription;

  AutoStartStopRule(
    PressureRepository pressureRepository,
    AbstractShotClock shotClock,
  ) {
    _pressureSubscription = pressureRepository.stream.listen((reading) {
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
        _enabled = false;
        shotClock.stop();
      }
    });
  }

  @override
  void enable() {
    if (_pressureSubscription != null && _pressureSubscription!.isPaused) {
      _pressureSubscription!.resume();
    }
    _enabled = true;
  }

  @override
  void disable() {
    if (_pressureSubscription != null) {
      _pressureSubscription!.pause();
    }
    _treshold2Reached = false;
    _enabled = false;
  }
}
