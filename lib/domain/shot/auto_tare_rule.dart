import 'package:espresso_log/domain/telemetry/scale_repository.dart';
import 'package:espresso_log/domain/telemetry/weight_reading.dart';

abstract class AbstractAutoTareRule {
  void enable();
  void disable();
}

class AutoTareRule implements AbstractAutoTareRule {
  final ScaleRepository scaleRepository;
  bool _enabled = false;
  List<WeightReading> _history = [];
  double? _startWeight;

  AutoTareRule(this.scaleRepository) {
    scaleRepository.stream
        .where((event) => event is WeightReading)
        .cast<WeightReading>()
        .listen((weightReading) {
          if (!_enabled) {
            return;
          }

          if (_startWeight == null) {
            _startWeight = weightReading.weight;
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
            scaleRepository.tareCommand();
            disable();
          }
        });
  }

  @override
  void enable() {
    _startWeight = null;
    _history = [];
    _enabled = true;
  }

  @override
  void disable() {
    _startWeight = null;
    _history = [];
    _enabled = false;
  }
}
