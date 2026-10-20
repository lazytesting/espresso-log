import 'dart:async';
import 'dart:math';

import 'package:rxdart/rxdart.dart';

/// Simulates the physical world behind the mock devices: a cup on a scale and
/// a machine pulling a shot. Both mock devices read from the same simulator, so
/// weight and pressure stay consistent with each other.
///
/// Idle by default (empty scale, 0 bar, no noise). Call [pullShot] to play a
/// scripted scenario: place cup, wait for auto-tare, preinfuse, pull, drip.
class MockShotSimulator {
  static const _tick = Duration(milliseconds: 100);
  static const cupWeight = 80.0;

  final _rawWeight = BehaviorSubject<double>.seeded(0);
  final _pressure = BehaviorSubject<double>.seeded(0);
  final _random = Random();
  Timer? _timer;
  Stopwatch? _scenario;
  double _coffee = 0;
  double _lastSeconds = 0;

  /// Weight on the scale in grams, including cup, ignoring any tare.
  Stream<double> get rawWeight => _rawWeight.stream;

  /// Pressure in bar.
  Stream<double> get pressure => _pressure.stream;

  double get currentRawWeight => _rawWeight.value;

  void start() {
    _timer ??= Timer.periodic(_tick, (_) => _step());
  }

  /// Removes any cup and starts a new scenario.
  void pullShot() {
    _coffee = 0;
    _lastSeconds = 0;
    _scenario = Stopwatch()..start();
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
  }

  void _step() {
    final scenario = _scenario;
    if (scenario == null) return;

    final t = scenario.elapsedMilliseconds / 1000;
    final dt = t - _lastSeconds;
    _lastSeconds = t;

    _coffee += _flow(t) * dt;
    final cupWeightNow = _cupWeight(t);
    _rawWeight.add(
      cupWeightNow == 0 ? 0 : cupWeightNow + _coffee + _noise(0.05),
    );

    final pressure = _pressureAt(t);
    _pressure.add(pressure == 0 ? 0 : max(0, pressure + _noise(0.05)));
  }

  double _noise(double amplitude) => (_random.nextDouble() * 2 - 1) * amplitude;

  /// Cup is lowered onto the scale between 0.5s and 1.0s.
  double _cupWeight(double t) {
    if (t < 0.5) return 0;
    return cupWeight * (t - 0.5).clamp(0, 0.5) / 0.5;
  }

  /// Lever goes up at 4s: 6s preinfusion at 3 bar, ramp to 9 bar, pull until
  /// 38s, then the pressure is released.
  double _pressureAt(double t) {
    if (t < 4) return 0;
    if (t < 5) return _lerp(t, 4, 5, 0, 3);
    if (t < 10) return 3;
    if (t < 13) return _lerp(t, 10, 13, 3, 9);
    if (t < 38) return 9;
    if (t < 39) return _lerp(t, 38, 39, 9, 0);
    return 0;
  }

  /// Coffee flow in g/s: first drops during preinfusion, steady flow while
  /// pulling, then an exponentially fading drip after pressure release.
  double _flow(double t) {
    if (t < 8) return 0;
    if (t < 16) return _lerp(t, 8, 16, 0, 1.4);
    if (t < 38) return 1.4;
    return 1.4 * exp(-(t - 38) / 1.5);
  }

  double _lerp(double t, double t0, double t1, double v0, double v1) =>
      v0 + (v1 - v0) * (t - t0) / (t1 - t0);
}
