import 'package:equatable/equatable.dart';
import 'package:espresso_log/main.dart';
import 'package:espresso_log/services/auto-start-stop/auto_start_stop_service.dart';
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
  final AbstractPressureService _pressureService =
      getIt.get<AbstractPressureService>();

  DateTime? _startDateTime;
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
        // TODO start listening
        _startDateTime = timerEvent.timeStamp;
        _pressureNotifications = [];
        _weightNotifications = [];
      } else if (timerEvent is TimerStoppedEvent) {
        // TODO stop listening
        _emitEvent(true);
        _startDateTime = null;
      }
    });
  }

  void _handleScaleUpdates() {
    _scaleService.stream.listen((scaleEvent) {
      if (_startDateTime == null) return;
      if (scaleEvent is TareNotification) {
        _weightNotifications = _weightNotifications
            .map((wn) => WeightNotification(weight: 0, timeStamp: wn.timeStamp))
            .toList();
      } else if (scaleEvent is WeightNotification) {
        _weightNotifications.add(scaleEvent);
      }
      _emitEvent();
    });
  }

  void _handlePressureUpdates() {
    _pressureService.stream.listen((pressureEvent) {
      if (_startDateTime == null) return;
      _pressureNotifications.add(pressureEvent);
      _emitEvent();
    });
  }

  void _emitEvent([bool isStopped = false]) {
    var pressureData = _pressureNotifications.map((pn) {
      return ShotGraphData(
          pn.timeStamp.difference(_startDateTime!).inMilliseconds, pn.pressure);
    }).toList();

    var weightData = _weightNotifications.map((wn) {
      return ShotGraphData(
          wn.timeStamp.difference(_startDateTime!).inMilliseconds, wn.weight);
    }).toList();

    if (isStopped) {
      emit(ShotGraphStopped(pressureData, weightData));
    } else {
      emit(ShotGraphUpdating(pressureData, weightData));
    }
  }

  void start() {
    emit(ShotGraphWaiting());
    _autoStartStopService.enable();
  }
}
