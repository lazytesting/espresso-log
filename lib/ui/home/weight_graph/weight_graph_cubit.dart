import 'package:espresso_log/main.dart';
import 'package:espresso_log/services/scale/abstract_scale_service.dart';
import 'package:espresso_log/services/scale/weight_notification.dart';
import 'package:espresso_log/services/timer/abstract_timer_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'weight_graph_state.dart';

class WeightGraphCubit extends Cubit<WeightGraphState> {
  final AbstractScaleService _scaleService = getIt.get<AbstractScaleService>();
  final AbstractTimerService _timerService = getIt.get<AbstractTimerService>();
  bool _isTimmerRunning = false;
  List<WeightNotification> _weightNotifications = [];
  DateTime? _startTime;

  List<GraphData> _getGraphData() {
    if (_weightNotifications.isEmpty) return [];
    if (_startTime == null) return []; //todo check
    var allGraphPoints = _weightNotifications.map((wn) => GraphData(
        wn.timeStamp.difference(_startTime!).inMilliseconds, wn.weight));

    List<GraphData> filteredList = [];
    int nextSecond = 0;

    for (GraphData point in allGraphPoints) {
      if (point.millisecond >= nextSecond) {
        filteredList.add(point);
        nextSecond += 1000;
      }
    }

    if (allGraphPoints.last.millisecond > filteredList.last.millisecond) {
      filteredList.add(allGraphPoints.last);
    }

    return filteredList.toList();
  }

  WeightGraphCubit() : super(WeightGraphInitial()) {
    emit(WeightGraphInitial());

    _timerService.timerUpdates.stream.listen((event) {
      if (event is TimerStartedEvent) {
        _isTimmerRunning = true;
        _startTime = DateTime.now();
      }
      if (event is TimerStoppedEvent) {
        _isTimmerRunning = false;
        emit(WeightGraphStopped(_getGraphData()));
        _weightNotifications = [];
        _startTime = null;
      }
    });

    _scaleService.weightNotificationController.stream.listen((event) {
      if (!_isTimmerRunning) return;
      _weightNotifications.add(event);
      emit(WeightGraphUpdating(_getGraphData()));
    });
  }
}
