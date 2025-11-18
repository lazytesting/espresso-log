import 'package:espresso_log/services/notification.dart';
import 'package:json_annotation/json_annotation.dart';

part 'weight_notification.g.dart';

@JsonSerializable()
class WeightNotification implements Notification {
  final double weight;
  @override
  final DateTime timeStamp;

  WeightNotification({required this.weight, required this.timeStamp});

  @override
  Map<String, dynamic> toJson() => _$WeightNotificationToJson(this);
}

@JsonSerializable()
class TareNotification implements Notification {
  @override
  final DateTime timeStamp;
  TareNotification({required this.timeStamp});
  @override
  Map<String, dynamic> toJson() => _$TareNotificationToJson(this);
}
