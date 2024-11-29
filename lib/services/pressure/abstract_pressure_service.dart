import 'package:espresso_log/services/pressure/pressure_notification.dart';
import 'package:rxdart/rxdart.dart';

abstract class AbstractPressureService {
  final pressureNotificationController =
      BehaviorSubject<PressureNotification>();
  Future<void> init() async {}

  void dispose();
}
