import 'package:espresso_log/services/scale/weight_notification.dart';

abstract class AbstractScaleService {
  Stream<ScaleNotification> stream = const Stream.empty();
  Future<void> init() async {}

  Future<void> tareCommand() async {}
}
