import 'package:espresso_log/domain/telemetry/scale_event.dart';

class TareEvent implements ScaleEvent {
  @override
  final DateTime timeStamp;

  TareEvent({required this.timeStamp});

  @override
  Map<String, dynamic> toJson() => {
    'type': 'TareEvent',
    'timeStamp': timeStamp.toIso8601String(),
  };
}
