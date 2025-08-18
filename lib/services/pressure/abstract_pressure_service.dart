import 'package:espresso_log/services/pressure/pressure_notification.dart';

abstract class AbstractPressureService {
  Stream<PressureNotification> stream = const Stream.empty();
  Future<void> init() async {}

  void dispose();
}
