import 'package:espresso_log/services/notification.dart';

abstract class AbstractScaleService {
  Stream<Notification> stream = const Stream.empty();
  Future<void> init() async {}

  Future<void> tareCommand() async {}
}
