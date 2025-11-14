// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'abstract_timer_service.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TimerStartedEvent _$TimerStartedEventFromJson(Map<String, dynamic> json) =>
    TimerStartedEvent(
      DateTime.parse(json['timeStamp'] as String),
      (json['milliSeconds'] as num).toInt(),
    );

Map<String, dynamic> _$TimerStartedEventToJson(TimerStartedEvent instance) =>
    <String, dynamic>{
      'timeStamp': instance.timeStamp.toIso8601String(),
      'milliSeconds': instance.milliSeconds,
    };

TimerStoppedEvent _$TimerStoppedEventFromJson(Map<String, dynamic> json) =>
    TimerStoppedEvent(
      DateTime.parse(json['timeStamp'] as String),
      (json['milliSeconds'] as num).toInt(),
    );

Map<String, dynamic> _$TimerStoppedEventToJson(TimerStoppedEvent instance) =>
    <String, dynamic>{
      'timeStamp': instance.timeStamp.toIso8601String(),
      'milliSeconds': instance.milliSeconds,
    };

TimerTickedEvent _$TimerTickedEventFromJson(Map<String, dynamic> json) =>
    TimerTickedEvent(
      DateTime.parse(json['timeStamp'] as String),
      (json['milliSeconds'] as num).toInt(),
    );

Map<String, dynamic> _$TimerTickedEventToJson(TimerTickedEvent instance) =>
    <String, dynamic>{
      'timeStamp': instance.timeStamp.toIso8601String(),
      'milliSeconds': instance.milliSeconds,
    };
