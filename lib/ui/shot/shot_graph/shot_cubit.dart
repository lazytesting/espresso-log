import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:espresso_log/devices/models/notification.dart';
import 'package:espresso_log/devices/pressure/models/abstract_pressure_service.dart';
import 'package:espresso_log/devices/scale/models/abstract_scale_service.dart';
import 'package:espresso_log/devices/scale/models/weight_notification.dart';
import 'package:espresso_log/devices/timer/abstract_timer_service.dart';
import 'package:espresso_log/devices/timer/models/timer_notification.dart';
import 'package:espresso_log/services/auto_start_stop_service.dart';
import 'package:espresso_log/services/auto_tare_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'shot_state.dart';

class ShotCubit extends Cubit<ShotState> {
  final AbstractAutoStartStopService _autoStartStopService;
  final AbstractScaleService _scaleService;
  final AbstractTimerService _timerService;
  final AbstractAutoTareService _autoTareService;
  final AbstractPressureService _pressureService;
  DateTime? _startDateTime;
  int? _lastReceivedTimeInmillis;
  bool _isRunning = false;
  List<ShotGraphData> _weightGraphData = [];
  List<ShotGraphData> _pressureGraphData = [];
  StreamSubscription<Notification>? _timerStreamSubscription;
  StreamSubscription<Notification>? _scaleStreamSubscription;
  StreamSubscription<Notification>? _pressureStreamSubscription;

  ShotCubit(
    this._autoStartStopService,
    this._scaleService,
    this._timerService,
    this._autoTareService,
    this._pressureService,
  ) : super(ShotStateInitial());

  void _handleTimerUpdates() {
    _timerStreamSubscription = _timerService.stream.listen((timerEvent) {
      _lastReceivedTimeInmillis = timerEvent.milliSeconds;
      if (timerEvent is TimerStartedNotification) {
        _isRunning = true;
        _startDateTime = timerEvent.timeStamp;
        _pressureGraphData = [];
        _weightGraphData = [];
      } else if (timerEvent is TimerStoppedNotification) {
        _pressureStreamSubscription?.pause();
        _scaleStreamSubscription?.pause();
        _isRunning = false;
        _autoTareService.stop();
        _emitEvent(true);
      } else {
        _emitEvent(false);
      }
    });
  }

  void _handleScaleUpdates() {
    _scaleStreamSubscription = _scaleService.stream.listen((scaleEvent) {
      if (_startDateTime == null || !_isRunning) return;
      var millisecond = scaleEvent.timeStamp
          .difference(_startDateTime!)
          .inMilliseconds;
      if (scaleEvent is TareNotification) {
        _weightGraphData = _weightGraphData.map((gd) {
          if (gd.millisecond <= millisecond) {
            return ShotGraphData(gd.millisecond, 0);
          }
          return gd;
        }).toList();
      } else if (scaleEvent is WeightNotification) {
        _weightGraphData.add(ShotGraphData(millisecond, scaleEvent.weight));
      }
      _emitEvent();
    });
  }

  void _handlePressureUpdates() {
    _pressureStreamSubscription = _pressureService.stream.listen((
      pressureEvent,
    ) {
      if (_startDateTime == null || !_isRunning) return;
      var millisecond = pressureEvent.timeStamp
          .difference(_startDateTime!)
          .inMilliseconds;
      _pressureGraphData.add(
        ShotGraphData(millisecond, pressureEvent.pressure),
      );
      _emitEvent();
    });
  }

  void _emitEvent([bool isStopped = false]) {
    var maxWeightAxis = 0;
    var maxPressureAxis = 0;

    emit(
      ShotStateUpdating(
        _pressureGraphData,
        _weightGraphData,
        maxWeightAxis,
        maxPressureAxis,
        (_lastReceivedTimeInmillis ?? 0) / 1000,
        _pressureGraphData.last.value,
        _weightGraphData.last.value,
        _getWeightChange(),
        isStopped,
      ),
    );
  }

  double? _getWeightChange() {
    if (_lastReceivedTimeInmillis == null) {
      // TODO log
      return null; //silent handle error
    }

    var relevantPressureData = _weightGraphData.where(
      (pgd) => pgd.millisecond > _lastReceivedTimeInmillis! - 500,
    );

    if (relevantPressureData.length < 2) {
      return null;
    }

    var first = relevantPressureData.first;
    var last = relevantPressureData.last;

    return (last.value - first.value) / (last.millisecond - first.millisecond);
  }

  void start() {
    _startDateTime = null;
    _isRunning = false;

    _handleTimerUpdates();
    _handleScaleUpdates();
    _handlePressureUpdates();
    _autoTareService.start();
    _autoStartStopService.enable();
  }

  void restart() {
    emit(ShotStateInitial());
    _startDateTime = null;
    _isRunning = false;
    _autoTareService.start();
    _autoStartStopService.enable();
  }

  @override
  Future<void> close() {
    _autoStartStopService.disable();
    _autoTareService.stop();
    _timerStreamSubscription?.cancel();
    _scaleStreamSubscription?.cancel();
    _pressureStreamSubscription?.cancel();

    return super.close();
  }
}
