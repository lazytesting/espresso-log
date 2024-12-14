import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:espresso_log/main.dart';
import 'package:espresso_log/services/scale/abstract_scale_service.dart';
import 'package:espresso_log/services/scale/weight_notification.dart';
import 'package:espresso_log/services/timer/abstract_timer_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'weight_graph_state.dart';

class WeightGraphCubit extends Cubit<WeightGraphState> {
  final AbstractScaleService _scaleService = getIt.get<AbstractScaleService>();
  final AbstractTimerService _timerService = getIt.get<AbstractTimerService>();
  late StreamSubscription<int> _timerSubscription;
  List<ScaleNotification> _scaleNotifications = [];
  late StreamSubscription<ScaleNotification> _scaleNotificationSubscription;

  List<GraphData> _getGraphData() {
    if (_scaleNotifications.isEmpty) return [];
    // create list with ordered weightNotifications
    List<WeightNotification> weightNotifications = [];
    weightNotifications
        .addAll(_scaleNotifications.whereType<WeightNotification>());
    weightNotifications.sort((a, b) => a.timeStamp.compareTo(b.timeStamp));

    // set everything before last tare to 0
    var tareEvents = _scaleNotifications.whereType<TareNotification>();

    var lastTareTime = tareEvents.isNotEmpty ? tareEvents.last.timeStamp : null;

    //weightNotifications.where((wn) => wn.timeStamp.isBefore(lastTareTime));
    var taredWeightNotifications = weightNotifications.map((wn) {
      var taredWeight =
          lastTareTime != null && wn.timeStamp.isBefore(lastTareTime)
              ? 0.0
              : wn.weight;
      return WeightNotification(weight: taredWeight, timeStamp: wn.timeStamp);
    });

    // map to graphData
    var timeStampZero = taredWeightNotifications.first.timeStamp;

    var allGraphPoints = taredWeightNotifications.map((wn) => GraphData(
        wn.timeStamp.difference(timeStampZero).inMilliseconds, wn.weight));

    // only one point per second
    // later add more advanced damping
    List<GraphData> filteredList = [];
    int nextSecond = 0;

    for (GraphData point in allGraphPoints) {
      if (point.millisecond >= nextSecond) {
        filteredList.add(point);
        nextSecond += 1000;
      }
    }

    return filteredList.toList();
  }

  WeightGraphCubit() : super(WeightGraphInitial()) {
    emit(WeightGraphInitial());

    _timerService.stream.listen((event) {
      if (event is TimerStartedEvent) {
        // reset scale notifications
        _scaleNotifications = [];

        // subscribe to scalenotifications
        _scaleNotificationSubscription =
            _scaleService.stream.listen((scaleEvent) {
          _scaleNotifications.add(scaleEvent);
        });

        // emit update every second
        var stream =
            Stream.periodic(const Duration(seconds: 1), (index) => index);
        _timerSubscription = stream.listen((onData) {
          emit(WeightGraphUpdating(_getGraphData()));
        });
      }
      if (event is TimerStoppedEvent) {
        _timerSubscription.cancel();
        emit(WeightGraphStopped(_getGraphData()));
        _scaleNotificationSubscription.cancel();
      }
    });
  }
}
