class PressureReading {
  final double pressure;
  final DateTime timeStamp;

  PressureReading(this.pressure, this.timeStamp);

  Map<String, dynamic> toJson() => {
    'type': 'PressureReading',
    'pressure': pressure,
    'timeStamp': timeStamp.toIso8601String(),
  };
}
