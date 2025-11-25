import 'package:equatable/equatable.dart';
import 'package:espresso_log/devices/scale/models/abstract_scale_service.dart';
import 'package:espresso_log/devices/scale/models/weight_notification.dart';
import 'package:espresso_log/main.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'weight_change_state.dart';

class WeightChangeCubit extends Cubit<WeightChangeState> {
  final AbstractScaleService _scaleService = getIt.get<AbstractScaleService>();
  final List<WeightNotification> _history = [];
  WeightChangeCubit() : super(WeightChangeInitial()) {
    _scaleService.stream.listen((event) {
      // remove event occured before taring
      if (event is TareNotification) {
        _history.removeWhere(
          (element) => element.timeStamp.isBefore(event.timeStamp),
        );
        return;
      }

      if (event is WeightNotification == false) return;

      // cleanup history
      var removeBefore = event.timeStamp.subtract(
        const Duration(milliseconds: 600),
      );
      _history.removeWhere(
        (element) => element.timeStamp.isBefore(removeBefore),
      );

      // add to history
      _history.add(event as WeightNotification);

      // emit average
      if (_history.length > 1) {
        var first = _history.first;
        var last = _history.last;
        var weightDiff = last.weight - first.weight;
        var duration = last.timeStamp
            .difference(first.timeStamp)
            .inMilliseconds;
        var weightChange = weightDiff / duration * 1000;
        emit(WeightChangeUpdated(weightChange));
      }
    });
  }
}
