import 'dart:async';
import 'dart:math';

import 'package:espresso_log/services/scale/abstract_scale_service.dart';
import 'package:espresso_log/services/scale/weight_notification.dart';
import 'package:rxdart/rxdart.dart';

class MockScaleService implements AbstractScaleService {
  final _scaleNotificationController = BehaviorSubject<ScaleNotification>();
  Timer? _timer;
  int _count = 0;
  @override
  Stream<ScaleNotification> stream = const Stream.empty();

  MockScaleService() {
    stream = _scaleNotificationController.stream.asBroadcastStream();
  }

  @override
  Future<void> init() async {
    _timer = Timer.periodic(const Duration(milliseconds: 200), (Timer t) {
      var weight = (_count / 5) + Random().nextDouble();
      if (t.tick >= 40 && t.tick <= 55) {
        weight = 52;
      }

      _scaleNotificationController
          .add(WeightNotification(weight: weight, timeStamp: DateTime.now()));
      _count++;
    });
  }

  @override
  Future<void> tareCommand() async {
    _scaleNotificationController
        .add(TareNotification(timeStamp: DateTime.now()));
    _count = 0;
  }

  void dispose() {
    _timer?.cancel();
  }
}
