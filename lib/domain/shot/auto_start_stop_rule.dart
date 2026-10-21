// lib/domain/shot/auto_start_stop_rule.dart
import 'package:espresso_log/domain/shot/abstract_shot_clock.dart';
import 'package:espresso_log/domain/telemetry/pressure_repository.dart';
import 'package:talker_flutter/talker_flutter.dart';

abstract class AbstractAutoStartStopRule {
  void enable();
  void disable();
}

class AutoStartStopRule implements AbstractAutoStartStopRule {
  bool _enabled = false;
  final double _treshold1 = 0.1;
  final double _treshold2 = 0.5;
  bool _treshold2Reached = false;
  final Talker? _talker;

  AutoStartStopRule(
    PressureRepository pressureRepository,
    AbstractShotClock shotClock, {
    Talker? talker,
  }) : _talker = talker {
    pressureRepository.stream.listen((reading) {
      if (!_enabled) {
        return;
      }

      // start
      if (!shotClock.isRunning && reading.pressure > _treshold1) {
        _talker?.info(
          'Shot start detected: pressure ${reading.pressure} bar > $_treshold1',
        );
        shotClock.start();
        return;
      }

      // treshold2 reached
      if (shotClock.isRunning && reading.pressure >= _treshold2) {
        if (!_treshold2Reached) {
          _talker?.info(
            'Pressure reached ${reading.pressure} bar (>= $_treshold2)',
          );
        }
        _treshold2Reached = true;
        return;
      }

      // below treshold2
      if (shotClock.isRunning &&
          _treshold2Reached &&
          reading.pressure < _treshold2) {
        _talker?.info(
          'Shot stop detected: pressure ${reading.pressure} bar < $_treshold2',
        );
        disable();
        shotClock.stop();
      }
    });
  }

  @override
  void enable() {
    _talker?.info('Auto start/stop enabled');
    _treshold2Reached = false;
    _enabled = true;
  }

  @override
  void disable() {
    if (_enabled) _talker?.info('Auto start/stop disabled');
    _treshold2Reached = false;
    _enabled = false;
  }
}
