import 'package:equatable/equatable.dart';
import 'package:espresso_log/main.dart';
import 'package:espresso_log/services/auto-start-stop/auto_start_stop_service.dart';
import 'package:espresso_log/services/auto-tare/auto_tare_service.dart';
import 'package:espresso_log/services/pressure/abstract_pressure_service.dart';
import 'package:espresso_log/services/pressure/pressure_notification.dart';
import 'package:espresso_log/services/scale/abstract_scale_service.dart';
import 'package:espresso_log/services/scale/weight_notification.dart';
import 'package:espresso_log/services/timer/abstract_timer_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'shot_graph_state.dart';

class ShotGraphCubit extends Cubit<ShotGraphState> {
  // keep 3 lists with data
  // apply some damping logic
  // on every new item emit an event (let bloc limit this)... or on every timer event

  final AutoStartStopService _autoStartStopService =
      getIt.get<AutoStartStopService>();
  final AbstractScaleService _scaleService = getIt.get<AbstractScaleService>();
  final AbstractTimerService _timerService = getIt.get<AbstractTimerService>();
  final AbstractAutoTareService _autoTareService =
      getIt.get<AbstractAutoTareService>();
  final AbstractPressureService _pressureService =
      getIt.get<AbstractPressureService>();

  DateTime? _startDateTime;
  DateTime? _tareDateTime;
  bool _isRunning = false;
  List<WeightNotification> _weightNotifications = [];
  List<PressureNotification> _pressureNotifications = [];

  ShotGraphCubit() : super(ShotGraphInitial()) {
    _handleTimerUpdates();
    _handleScaleUpdates();
    _handlePressureUpdates();
  }

  void _handleTimerUpdates() {
    _timerService.stream.listen((timerEvent) {
      if (timerEvent is TimerStartedEvent) {
        _isRunning = true;
        _startDateTime = timerEvent.timeStamp;
        _pressureNotifications = [];
        _weightNotifications = [];
      } else if (timerEvent is TimerStoppedEvent) {
        // TODO stop listening
        _isRunning = false;
        _autoTareService.stop();
        _emitEvent(true);
        _startDateTime = null;
      }
    });
  }

  void _handleScaleUpdates() {
    _scaleService.stream.listen((scaleEvent) {
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
    _pressureService.stream.listen((pressureEvent) {
      if (_startDateTime == null || !_isRunning) return;
      _pressureNotifications.add(pressureEvent);
      _emitEvent();
    });
  }

  void _emitEvent([bool isStopped = false]) {
    var pressureData = _pressureNotifications.map((pn) {
      return ShotGraphData(
          pn.timeStamp.difference(_startDateTime!).inMilliseconds, pn.pressure);
    }).toList();

    // retrospectively tare anything before the first 0 weight event after the tare command
    var tareAllBefore = _weightNotifications
        .firstWhere(
            (element) =>
                element.timeStamp.isAfter(_tareDateTime!) &&
                element.weight == 0,
            orElse: () => _weightNotifications.first)
        .timeStamp;

    var weightData = _weightNotifications.map((ele) {
      if (ele.timeStamp.isBefore(tareAllBefore)) {
        return ShotGraphData(
            ele.timeStamp.difference(_startDateTime!).inMilliseconds, 0);
      } else {
        return ShotGraphData(
            ele.timeStamp.difference(_startDateTime!).inMilliseconds,
            ele.weight);
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
    _autoTareService.start();
    _autoStartStopService.enable();
  }
}
