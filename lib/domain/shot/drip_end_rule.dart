import 'dart:async';

import 'package:espresso_log/domain/shot/abstract_shot_clock.dart';
import 'package:espresso_log/domain/shot/timer_event.dart';
import 'package:espresso_log/domain/telemetry/scale_repository.dart';
import 'package:espresso_log/domain/telemetry/weight_reading.dart';

class DripEnded {
  final DateTime timeStamp;

  DripEnded(this.timeStamp);
}

abstract class AbstractDripEndRule {
  Stream<DripEnded> get stream;
}

/// After a shot stops, coffee often keeps dripping into the cup. The drip
/// phase starts when the shot clock stops and ends when no weight was added
/// for [settleDuration], but never later than [maxDuration] after the stop.
class DripEndRule implements AbstractDripEndRule {
  final ScaleRepository scaleRepository;
  final Duration settleDuration;
  final Duration maxDuration;

  /// Smallest weight gain that counts as "weight added" (scale resolution).
  static const weightEpsilon = 0.1;

  final _controller = StreamController<DripEnded>.broadcast();
  StreamSubscription<WeightReading>? _weightSubscription;
  Timer? _settleTimer;
  Timer? _maxTimer;
  double? _baselineWeight;

  DripEndRule(
    this.scaleRepository,
    AbstractShotClock shotClock, {
    this.settleDuration = const Duration(seconds: 1),
    this.maxDuration = const Duration(seconds: 5),
  }) {
    shotClock.stream.listen((event) {
      if (event is TimerStopped) _beginDrip();
      if (event is TimerStarted) _reset();
    });
  }

  @override
  Stream<DripEnded> get stream => _controller.stream;

  void _beginDrip() {
    _reset();
    _settleTimer = Timer(settleDuration, _endDrip);
    _maxTimer = Timer(maxDuration, _endDrip);
    _weightSubscription = scaleRepository.stream
        .where((event) => event is WeightReading)
        .cast<WeightReading>()
        .listen(_onWeight);
  }

  void _onWeight(WeightReading reading) {
    final baseline = _baselineWeight;
    if (baseline == null) {
      _baselineWeight = reading.weight;
    } else if (reading.weight - baseline >= weightEpsilon) {
      _baselineWeight = reading.weight;
      _settleTimer?.cancel();
      _settleTimer = Timer(settleDuration, _endDrip);
    }
  }

  void _endDrip() {
    _reset();
    _controller.add(DripEnded(DateTime.now()));
  }

  void _reset() {
    _weightSubscription?.cancel();
    _weightSubscription = null;
    _settleTimer?.cancel();
    _maxTimer?.cancel();
    _baselineWeight = null;
  }
}
