// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'timer_notification.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TimerStartedNotification _$TimerStartedNotificationFromJson(
  Map<String, dynamic> json,
) => TimerStartedNotification(
  DateTime.parse(json['timeStamp'] as String),
  (json['milliSeconds'] as num).toInt(),
);

Map<String, dynamic> _$TimerStartedNotificationToJson(
  TimerStartedNotification instance,
) => <String, dynamic>{
  'timeStamp': instance.timeStamp.toIso8601String(),
  'milliSeconds': instance.milliSeconds,
};

TimerStoppedNotification _$TimerStoppedNotificationFromJson(
  Map<String, dynamic> json,
) => TimerStoppedNotification(
  DateTime.parse(json['timeStamp'] as String),
  (json['milliSeconds'] as num).toInt(),
);

Map<String, dynamic> _$TimerStoppedNotificationToJson(
  TimerStoppedNotification instance,
) => <String, dynamic>{
  'timeStamp': instance.timeStamp.toIso8601String(),
  'milliSeconds': instance.milliSeconds,
};

TimerTickedNotification _$TimerTickedNotificationFromJson(
  Map<String, dynamic> json,
) => TimerTickedNotification(
  DateTime.parse(json['timeStamp'] as String),
  (json['milliSeconds'] as num).toInt(),
);

Map<String, dynamic> _$TimerTickedNotificationToJson(
  TimerTickedNotification instance,
) => <String, dynamic>{
  'timeStamp': instance.timeStamp.toIso8601String(),
  'milliSeconds': instance.milliSeconds,
};
