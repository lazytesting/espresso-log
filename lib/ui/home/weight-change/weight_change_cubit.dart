import 'package:espresso_log/services/scale/abstract_scale_service.dart';
import 'package:espresso_log/main.dart';
import 'package:espresso_log/services/scale/weight_notification.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'weight_change_state.dart';

class WeightChangeCubit extends Cubit<WeightChangeState> {
  final AbstractScaleService _scaleService = getIt.get<AbstractScaleService>();
  final List<WeightNotification> _history = [];
  WeightChangeCubit() : super(WeightChangeInitial()) {
    _scaleService.weightNotificationController.stream.listen((event) {
      // prevent out of order events
      if (_history.isNotEmpty &&
          _history.last.timeStamp.millisecondsSinceEpoch >
              event.timeStamp.millisecondsSinceEpoch) {
        return;
      }

      _history.add(event);

      // cleanup history
      var removeBefore =
          _history.last.timeStamp.subtract(const Duration(microseconds: 600));
      _history
          .removeWhere((element) => element.timeStamp.isBefore(removeBefore));

      // emit average
      if (_history.length > 1) {
        var first = _history.first;
        var last = _history.last;
        var weightDiff = last.weight - first.weight;
        var duration =
            last.timeStamp.difference(first.timeStamp).inMilliseconds;
        var weightChange = weightDiff / duration * 1000;
        emit(WeightChangeUpdated(weightChange));
      }
    });
  }
}
