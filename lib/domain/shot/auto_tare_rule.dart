import 'package:espresso_log/domain/telemetry/scale_repository.dart';
import 'package:espresso_log/domain/telemetry/weight_reading.dart';
import 'package:talker_flutter/talker_flutter.dart';

abstract class AbstractAutoTareRule {
  void enable();
  void disable();
}

class AutoTareRule implements AbstractAutoTareRule {
  final ScaleRepository scaleRepository;
  final Talker? _talker;
  bool _enabled = false;
  List<WeightReading> _history = [];
  double? _startWeight;

  AutoTareRule(this.scaleRepository, {Talker? talker}) : _talker = talker {
    scaleRepository.stream
        .where((event) => event is WeightReading)
        .cast<WeightReading>()
        .listen((weightReading) {
          if (!_enabled) {
            return;
          }

          if (_startWeight == null) {
            _startWeight = weightReading.weight;
            _talker?.info(
              'Auto tare: baseline weight ${weightReading.weight}g',
            );
            return;
          }

          if (weightReading.weight < _startWeight! + 50) {
            _history = [];
            return;
          }

          // first 'interesting' weight
          // just store
          if (_history.isEmpty) {
            _history.add(weightReading);
            return;
          }

          // weight not stable: reset
          if (weightReading.weight - 0.2 > _history.last.weight ||
              weightReading.weight + 0.2 < _history.last.weight) {
            _history = [];
            _history.add(weightReading);
            return;
          }

          // weight is stable
          _history.add(weightReading);
          if (weightReading.timeStamp
                  .difference(_history.first.timeStamp)
                  .inMilliseconds >
              1000) {
            _talker?.info(
              'Auto tare: weight stable at ${weightReading.weight}g for >1s, '
              'sending tare',
            );
            scaleRepository.tareCommand();
            disable();
          }
        });
  }

  @override
  void enable() {
    _talker?.info('Auto tare enabled');
    _startWeight = null;
    _history = [];
    _enabled = true;
  }

  @override
  void disable() {
    if (_enabled) _talker?.info('Auto tare disabled');
    _startWeight = null;
    _history = [];
    _enabled = false;
  }
}
