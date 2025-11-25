import 'package:espresso_log/devices/models/notification.dart';

abstract class AbstractScaleService {
  Stream<Notification> stream = const Stream.empty();
  Future<void> init() async {}

  Future<void> tareCommand() async {}
}
