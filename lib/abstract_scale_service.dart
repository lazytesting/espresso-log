import 'package:espresso_log/weight_notification.dart';
import 'package:rxdart/rxdart.dart';

abstract class AbstractScaleService {
  final weightNotificationController = BehaviorSubject<WeightNotification>();
  Future<void> init() async {}

  Future<void> tareCommand() async {}
}
