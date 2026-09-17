abstract class TimerEvent {
  final DateTime timeStamp;
  final int milliSeconds;

  TimerEvent(this.timeStamp, this.milliSeconds);

  Map<String, dynamic> toJson();
}

class TimerStarted extends TimerEvent {
  TimerStarted(super.timeStamp, super.milliSeconds);

  @override
  Map<String, dynamic> toJson() => {
    'type': 'TimerStarted',
    'milliSeconds': milliSeconds,
    'timeStamp': timeStamp.toIso8601String(),
  };
}

class TimerTicked extends TimerEvent {
  TimerTicked(super.timeStamp, super.milliSeconds);

  @override
  Map<String, dynamic> toJson() => {
    'type': 'TimerTicked',
    'milliSeconds': milliSeconds,
    'timeStamp': timeStamp.toIso8601String(),
  };
}

class TimerStopped extends TimerEvent {
  TimerStopped(super.timeStamp, super.milliSeconds);

  @override
  Map<String, dynamic> toJson() => {
    'type': 'TimerStopped',
    'milliSeconds': milliSeconds,
    'timeStamp': timeStamp.toIso8601String(),
  };
}
