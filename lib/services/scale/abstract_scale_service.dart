import 'package:espresso_log/services/scale/weight_notification.dart';
import 'package:rxdart/rxdart.dart';

abstract class AbstractScaleService {
  final scaleNotificationController = BehaviorSubject<ScaleNotification>();
  Future<void> init() async {}

  Future<void> tareCommand() async {}
}
