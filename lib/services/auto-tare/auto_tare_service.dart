import 'dart:async';

import 'package:espresso_log/devices/scale/models/abstract_scale_service.dart';
import 'package:espresso_log/devices/scale/models/weight_notification.dart';

abstract class AbstractAutoTareService {
  void start();
  void stop();
}

class AutoTareService implements AbstractAutoTareService {
  final AbstractScaleService scaleService;
  StreamSubscription? scaleSubscription;
  List<WeightNotification> _history = [];
  double? _startWeight;

  AutoTareService(this.scaleService);

  @override
  void start() {
    scaleSubscription = scaleService.stream
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
        });
  }

  @override
  void stop() {
    scaleSubscription?.cancel();
    _startWeight = null;
    _history = [];
  }
}
