// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'weight_notification.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WeightNotification _$WeightNotificationFromJson(Map<String, dynamic> json) =>
    WeightNotification(
      weight: (json['weight'] as num).toDouble(),
      timeStamp: DateTime.parse(json['timeStamp'] as String),
    );

Map<String, dynamic> _$WeightNotificationToJson(WeightNotification instance) =>
    <String, dynamic>{
      'weight': instance.weight,
      'timeStamp': instance.timeStamp.toIso8601String(),
    };

TareNotification _$TareNotificationFromJson(Map<String, dynamic> json) =>
    TareNotification(timeStamp: DateTime.parse(json['timeStamp'] as String));

Map<String, dynamic> _$TareNotificationToJson(TareNotification instance) =>
    <String, dynamic>{'timeStamp': instance.timeStamp.toIso8601String()};
