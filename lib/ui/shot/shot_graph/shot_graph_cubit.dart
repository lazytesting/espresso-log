// lib/ui/shot/shot_graph/shot_graph_cubit.dart
import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:espresso_log/domain/settings/settings_repository.dart';
import 'package:espresso_log/domain/shot/abstract_shot_clock.dart';
import 'package:espresso_log/domain/shot/auto_start_stop_rule.dart';
import 'package:espresso_log/domain/shot/auto_tare_rule.dart';
import 'package:espresso_log/domain/shot/drip_end_rule.dart';
import 'package:espresso_log/domain/shot/shot_graph_point.dart';
import 'package:espresso_log/domain/shot/shot_metrics.dart';
import 'package:espresso_log/domain/shot/shot_recording_session.dart';
import 'package:espresso_log/domain/shot/shot_snapshot.dart';
import 'package:espresso_log/domain/shot/timer_event.dart';
import 'package:espresso_log/domain/telemetry/pressure_reading.dart';
import 'package:espresso_log/domain/telemetry/pressure_repository.dart';
import 'package:espresso_log/domain/telemetry/scale_event.dart';
import 'package:espresso_log/domain/telemetry/scale_repository.dart';
import 'package:espresso_log/domain/telemetry/tare_event.dart';
import 'package:espresso_log/domain/telemetry/weight_reading.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talker_flutter/talker_flutter.dart';

part 'shot_graph_state.dart';

class ShotGraphCubit extends Cubit<ShotGraphState> {
  final AbstractAutoStartStopRule _autoStartStopRule;
  final ScaleRepository _scaleRepository;
  final AbstractShotClock _shotClock;
  final AbstractAutoTareRule _autoTareRule;
  final PressureRepository _pressureRepository;
  final AbstractDripEndRule _dripEndRule;
  final SettingsRepository _settings;
  final Talker? _talker;
  late ShotRecordingSession _session = _newSession();
  StreamSubscription<TimerEvent>? _timerStreamSubscription;
  StreamSubscription<ScaleEvent>? _scaleStreamSubscription;
  StreamSubscription<PressureReading>? _pressureStreamSubscription;
  StreamSubscription<DripEnded>? _dripEndSubscription;

  ShotGraphCubit(
    this._autoStartStopRule,
    this._scaleRepository,
    this._shotClock,
    this._autoTareRule,
    this._pressureRepository,
    this._dripEndRule,
    this._settings, {
    Talker? talker,
  }) : _talker = talker,
       super(ShotGraphInitial());

  void _handleTimerUpdates() {
    _timerStreamSubscription = _shotClock.stream.listen((timerEvent) {
      switch (timerEvent) {
        case TimerStarted():
          _talker?.info('Shot recording started');
          _session.start(timerEvent.timeStamp);
        case TimerTicked():
          _session.tick(timerEvent.timeStamp);
        case TimerStopped():
          _talker?.info('Pour ended, dripping');
          _autoTareRule.disable();
          _session.endPour(timerEvent.timeStamp);
        default:
          return;
      }
      _emitUpdating();
    });
  }

  void _handleDripEnd() {
    _dripEndSubscription = _dripEndRule.stream.listen((dripEnded) {
      if (!_session.isDripping) return;
      _talker?.info('Shot recording stopped');
      _session.stop(dripEnded.timeStamp);
      emit(ShotGraphStopped(_session.snapshot));
    });
  }

  void _emitUpdating() => emit(ShotGraphUpdating(_session.snapshot));

  void _handleScaleUpdates() {
    _scaleStreamSubscription = _scaleRepository.stream.listen((scaleEvent) {
      if (scaleEvent is TareEvent) {
        _talker?.info('Tare confirmed by scale');
        _session.tare(scaleEvent.timeStamp);
      } else if (scaleEvent is WeightReading) {
        _session.addWeight(scaleEvent);
        if (_session.isDripping) _emitUpdating();
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

  ShotRecordingSession _newSession() => ShotRecordingSession(
    startCompensation: Duration(
      seconds: _settings.startDelayCompensationSeconds,
    ),
  );

  void start() {
    _talker?.info('Shot screen started, waiting for shot');
    emit(ShotGraphWaiting());
    _session = _newSession();

    _handleTimerUpdates();
    _handleScaleUpdates();
    _handlePressureUpdates();
    _handleDripEnd();
    _autoTareRule.enable();
    _autoStartStopRule.enable();
  }

  void restart() {
    _talker?.info('Shot restarted, waiting for shot');
    emit(ShotGraphWaiting());
    _session = _newSession();
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
    _dripEndSubscription?.cancel();

    return super.close();
  }
}
