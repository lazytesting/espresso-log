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
  ShotRecordingSession _session = ShotRecordingSession();
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
        _session.start(timerEvent.timeStamp);
        emit(
          ShotGraphUpdating(
            _session.snapshot.pressureData,
            _session.snapshot.weightData,
          ),
        );
      }
      if (timerEvent is TimerStopped) {
        _autoTareRule.disable();
        final snapshot = _session.snapshot;
        emit(ShotGraphStopped(snapshot.pressureData, snapshot.weightData));
      }

      if (timerEvent is TimerTicked) {
        final snapshot = _session.snapshot;
        emit(ShotGraphUpdating(snapshot.pressureData, snapshot.weightData));
      }
    });
  }

  void _handleScaleUpdates() {
    _scaleStreamSubscription = _scaleRepository.stream.listen((scaleEvent) {
      if (scaleEvent is TareEvent) {
        _session.tare(scaleEvent.timeStamp);
      } else if (scaleEvent is WeightReading) {
        _session.addWeight(scaleEvent);
      }
    });
  }

  void _handlePressureUpdates() {
    _pressureStreamSubscription = _pressureRepository.stream.listen((
      pressureReading,
    ) {
      _session.addPressure(pressureReading);
    });
  }

  void start() {
    emit(ShotGraphWaiting());
    _session = ShotRecordingSession();

    _handleTimerUpdates();
    _handleScaleUpdates();
    _handlePressureUpdates();
    _autoTareRule.enable();
    _autoStartStopRule.enable();
  }

  void restart() {
    emit(ShotGraphWaiting());
    _session = ShotRecordingSession();
    _autoTareRule.enable();
    _autoStartStopRule.enable();
  }

  @override
  Future<void> close() {
    _autoStartStopRule.disable();
    _autoTareRule.disable();
    _timerStreamSubscription?.cancel();
    _scaleStreamSubscription?.cancel();
    _pressureStreamSubscription?.cancel();

    return super.close();
  }
}
