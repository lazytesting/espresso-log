import '../notification.dart';
import 'package:json_annotation/json_annotation.dart';

part 'pressure_notification.g.dart';

@JsonSerializable()
class PressureNotification implements Notification {
  @override
  final DateTime timeStamp;
  final double pressure;

  PressureNotification(this.pressure, this.timeStamp);
  Map<String, dynamic> toJson() => _$PressureNotificationToJson(this);
}
