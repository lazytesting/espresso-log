// lib/ui/shot/shot_graph/shot_graph_cubit.dart
import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:espresso_log/domain/shot/abstract_shot_clock.dart';
import 'package:espresso_log/domain/shot/auto_start_stop_rule.dart';
import 'package:espresso_log/domain/shot/auto_tare_rule.dart';
import 'package:espresso_log/domain/shot/shot_graph_point.dart';
import 'package:espresso_log/domain/shot/shot_recording_session.dart';
import 'package:espresso_log/domain/shot/timer_event.dart';
import 'package:espresso_log/domain/telemetry/pressure_reading.dart';
import 'package:espresso_log/domain/telemetry/pressure_repository.dart';
import 'package:espresso_log/domain/telemetry/scale_event.dart';
import 'package:espresso_log/domain/telemetry/scale_repository.dart';
import 'package:espresso_log/domain/telemetry/tare_event.dart';
import 'package:espresso_log/domain/telemetry/weight_reading.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'shot_graph_state.dart';

class ShotGraphCubit extends Cubit<ShotGraphState> {
  final AbstractAutoStartStopRule _autoStartStopRule;
  final ScaleRepository _scaleRepository;
  final AbstractShotClock _shotClock;
  final AbstractAutoTareRule _autoTareRule;
  final PressureRepository _pressureRepository;
  final ShotRecordingSession _session = ShotRecordingSession();
  bool _isRunning = false;
  StreamSubscription<TimerEvent>? _timerStreamSubscription;
  StreamSubscription<ScaleEvent>? _scaleStreamSubscription;
  StreamSubscription<PressureReading>? _pressureStreamSubscription;

  ShotGraphCubit(
    this._autoStartStopRule,
    this._scaleRepository,
    this._shotClock,
    this._autoTareRule,
    this._pressureRepository,
  ) : super(ShotGraphInitial());

  void _handleTimerUpdates() {
    _timerStreamSubscription = _shotClock.stream.listen((timerEvent) {
      if (timerEvent is TimerStarted) {
        _isRunning = true;
        _session.start(timerEvent.timeStamp);
      } else if (timerEvent is TimerStopped) {
        _isRunning = false;
        _autoTareRule.stop();
        final snapshot = _session.snapshot;
        emit(ShotGraphStopped(snapshot.pressureData, snapshot.weightData));
        _session.stop();
      }
    });
  }

  void _handleScaleUpdates() {
    _scaleStreamSubscription = _scaleRepository.stream.listen((scaleEvent) {
      if (!_session.isStarted || !_isRunning) return;
      if (scaleEvent is TareEvent) {
        _session.tare(scaleEvent.timeStamp);
      } else if (scaleEvent is WeightReading) {
        _session.addWeight(scaleEvent);
      }
      final snapshot = _session.snapshot;
      emit(ShotGraphUpdating(snapshot.pressureData, snapshot.weightData));
    });
  }

  void _handlePressureUpdates() {
    _pressureStreamSubscription = _pressureRepository.stream.listen((
      pressureReading,
    ) {
      if (!_session.isStarted || !_isRunning) return;
      _session.addPressure(pressureReading);
      final snapshot = _session.snapshot;
      emit(ShotGraphUpdating(snapshot.pressureData, snapshot.weightData));
    });
  }

  void start() {
    emit(ShotGraphWaiting());
    _isRunning = false;
    _session.reset();

    _handleTimerUpdates();
    _handleScaleUpdates();
    _handlePressureUpdates();
    _autoTareRule.start();
    _autoStartStopRule.enable();
  }

  void restart() {
    emit(ShotGraphWaiting());
    _isRunning = false;
    _session.reset();
    _autoTareRule.start();
    _autoStartStopRule.enable();
  }

  @override
  Future<void> close() {
    _autoStartStopRule.disable();
    _autoTareRule.stop();
    _timerStreamSubscription?.cancel();
    _scaleStreamSubscription?.cancel();
    _pressureStreamSubscription?.cancel();

    return super.close();
  }
}
