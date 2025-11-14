// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pressure_notification.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PressureNotification _$PressureNotificationFromJson(
  Map<String, dynamic> json,
) => PressureNotification(
  (json['pressure'] as num).toDouble(),
  DateTime.parse(json['timeStamp'] as String),
);

Map<String, dynamic> _$PressureNotificationToJson(
  PressureNotification instance,
) => <String, dynamic>{
  'timeStamp': instance.timeStamp.toIso8601String(),
  'pressure': instance.pressure,
};
