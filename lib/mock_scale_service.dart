import 'dart:async';
import 'dart:math';

import 'package:espresso_log/abstract_scale_service.dart';
import 'package:espresso_log/weight_notification.dart';
import 'package:rxdart/rxdart.dart';

class MockScaleService implements AbstractScaleService {
  @override
  final weightNotificationController = BehaviorSubject<WeightNotification>();
  Timer? _timer;
  int _count = 0;

  @override
  Future<void> init() async {
    _timer = Timer.periodic(const Duration(milliseconds: 200), (Timer t) {
      weightNotificationController.add(WeightNotification(
          weight: (_count / 5) + Random().nextDouble(),
          isStable: true,
          millisSinceOn: DateTime.now().millisecondsSinceEpoch));
      _count++;
    });
  }

  @override
  Future<void> tareCommand() async {
    weightNotificationController.add(WeightNotification(
        weight: 0,
        isStable: true,
        millisSinceOn: DateTime.now().millisecondsSinceEpoch));
    _count = 0;
  }

  void dispose() {
    _timer?.cancel();
  }
}
