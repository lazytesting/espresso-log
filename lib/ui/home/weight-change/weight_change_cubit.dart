import 'package:espresso_log/abstract_scale_service.dart';
import 'package:espresso_log/main.dart';
import 'package:espresso_log/weight_notification.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'weight_change_state.dart';

class WeightChangeCubit extends Cubit<WeightChangeState> {
  final AbstractScaleService _scaleService = getIt.get<AbstractScaleService>();
  final List<WeightNotification> _history = [];
  WeightChangeCubit() : super(WeightChangeInitial()) {
    _scaleService.weightNotificationController.stream.listen((event) {
      // prevent out of order events
      if (_history.isNotEmpty &&
          _history.last.millisSinceOn > event.millisSinceOn) {
        return;
      }

      _history.add(event);

      // cleanup history
      var removeBefore = _history.last.millisSinceOn - 600;
      _history.removeWhere((element) => element.millisSinceOn < removeBefore);

      // emit average
      if (_history.length > 1) {
        var first = _history.first;
        var last = _history.last;
        var weightDiff = last.weight - first.weight;
        var duration = last.millisSinceOn - first.millisSinceOn;
        var weightChange = weightDiff / duration * 1000;
        emit(WeightChangeUpdated(weightChange));
      }
    });
  }
}
