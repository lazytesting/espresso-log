import 'package:espresso_log/domain/telemetry/scale_event.dart';

class WeightReading implements ScaleEvent {
  final double weight;
  @override
  final DateTime timeStamp;

  WeightReading({required this.weight, required this.timeStamp});

  @override
  Map<String, dynamic> toJson() => {
    'type': 'WeightReading',
    'weight': weight,
    'timeStamp': timeStamp.toIso8601String(),
  };
}
