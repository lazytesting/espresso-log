import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:espresso_log/devices/models/notification.dart';
import 'package:espresso_log/devices/pressure/models/abstract_pressure_service.dart';
import 'package:espresso_log/devices/pressure/models/pressure_notification.dart';
import 'package:espresso_log/devices/scale/models/abstract_scale_service.dart';
import 'package:espresso_log/devices/scale/models/weight_notification.dart';
import 'package:espresso_log/devices/timer/abstract_timer_service.dart';
import 'package:espresso_log/devices/timer/models/timer_notification.dart';
import 'package:espresso_log/services/auto_start_stop_service.dart';
import 'package:espresso_log/services/auto_tare_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'shot_graph_state.dart';

class ShotGraphCubit extends Cubit<ShotGraphState> {
  // keep 3 lists with data
  // apply some damping logic
  // on every new item emit an event (let bloc limit this)... or on every timer event

  final AbstractAutoStartStopService _autoStartStopService;
  final AbstractScaleService _scaleService;
  final AbstractTimerService _timerService;
  final AbstractAutoTareService _autoTareService;
  final AbstractPressureService _pressureService;
  DateTime? _startDateTime;
  DateTime? _tareDateTime;
  bool _isRunning = false;
  List<WeightNotification> _weightNotifications = [];
  List<PressureNotification> _pressureNotifications = [];
  StreamSubscription<Notification>? _timerStreamSubscription;
  StreamSubscription<Notification>? _scaleStreamSubscription;
  StreamSubscription<Notification>? _pressureStreamSubscription;

  ShotGraphCubit(
    this._autoStartStopService,
    this._scaleService,
    this._timerService,
    this._autoTareService,
    this._pressureService,
  ) : super(ShotGraphInitial());

  void _handleTimerUpdates() {
    _timerStreamSubscription = _timerService.stream.listen((timerEvent) {
      if (timerEvent is TimerStartedNotification) {
        _isRunning = true;
        _startDateTime = timerEvent.timeStamp;
        _pressureNotifications = [];
        _weightNotifications = [];
      } else if (timerEvent is TimerStoppedNotification) {
        // TODO stop listening
        _isRunning = false;
        _autoTareService.stop();
        _emitEvent(true);
        _startDateTime = null;
      }
    });
  }

  void _handleScaleUpdates() {
    _scaleStreamSubscription = _scaleService.stream.listen((scaleEvent) {
      if (_startDateTime == null || !_isRunning) return;
      if (scaleEvent is TareNotification) {
        _tareDateTime = scaleEvent.timeStamp;
      } else if (scaleEvent is WeightNotification) {
        _weightNotifications.add(scaleEvent);
      }
      _emitEvent();
    });
  }

  void _handlePressureUpdates() {
    _pressureStreamSubscription = _pressureService.stream.listen((
      pressureEvent,
    ) {
      if (_startDateTime == null || !_isRunning) return;
      _pressureNotifications.add(pressureEvent);
      _emitEvent();
    });
  }

  void _emitEvent([bool isStopped = false]) {
    var pressureData = _pressureNotifications.map((pn) {
      return ShotGraphData(
        pn.timeStamp.difference(_startDateTime!).inMilliseconds,
        pn.pressure,
      );
    }).toList();

    var weightData = _weightNotifications.map((ele) {
      if (_tareDateTime == null || ele.timeStamp.isAfter(_tareDateTime!)) {
        return ShotGraphData(
          ele.timeStamp.difference(_startDateTime!).inMilliseconds,
          ele.weight,
        );
      } else {
        return ShotGraphData(
          ele.timeStamp.difference(_startDateTime!).inMilliseconds,
          0,
        );
      }
    }).toList();

    if (isStopped) {
      emit(ShotGraphStopped(pressureData, weightData));
    } else {
      emit(ShotGraphUpdating(pressureData, weightData));
    }
  }

  void start() {
    emit(ShotGraphWaiting());
    _startDateTime = null;
    _tareDateTime = null;
    _isRunning = false;
    _weightNotifications = [];
    _pressureNotifications = [];

    _handleTimerUpdates();
    _handleScaleUpdates();
    _handlePressureUpdates();
    _autoTareService.start();
    _autoStartStopService.enable();
  }

  void restart() {
    emit(ShotGraphWaiting());
    _startDateTime = null;
    _tareDateTime = null;
    _isRunning = false;
    _weightNotifications = [];
    _pressureNotifications = [];
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
