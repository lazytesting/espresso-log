import 'dart:async';

import 'package:espresso_log/devices/scale/models/abstract_scale_service.dart';
import 'package:espresso_log/devices/scale/models/weight_notification.dart';

abstract class AbstractAutoTareService {
  void start();
  void stop();
  void restart();
}

class AutoTareService implements AbstractAutoTareService {
  final AbstractScaleService scaleService;
  StreamSubscription? _scaleSubscription;
  List<WeightNotification> _history = [];
  double? _startWeight;

  AutoTareService(this.scaleService) {
    _scaleSubscription = scaleService.stream
        .where((event) => event is WeightNotification)
        .cast<WeightNotification>()
        .listen((weightNotification) {
          if (_startWeight == null) {
            _startWeight = weightNotification.weight;
            return;
          }

          if (weightNotification.weight < _startWeight! + 50) {
            _history = [];
            return;
          }

          // first 'interesting' weight
          // just store
          if (_history.isEmpty) {
            _history.add(weightNotification);
            return;
          }

          // weight not stable: reset
          if (weightNotification.weight - 0.2 > _history.last.weight ||
              weightNotification.weight + 0.2 < _history.last.weight) {
            _history = [];
            _history.add(weightNotification);
            return;
          }

          // weight is stable
          _history.add(weightNotification);
          if (weightNotification.timeStamp
                  .difference(_history.first.timeStamp)
                  .inMilliseconds >
              1000) {
            scaleService.tareCommand();
            stop();
          }
        })..pause();
  }

  @override
  void start() {
    _scaleSubscription!.resume();
  }

  @override
  void restart() {
    _startWeight = null;
    _history = [];
  }

  @override
  void stop() {
    _scaleSubscription!.pause();
    _startWeight = null;
    _history = [];
  }
}
