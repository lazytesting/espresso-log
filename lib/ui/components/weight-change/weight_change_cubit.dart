import 'package:equatable/equatable.dart';
import 'package:espresso_log/domain/telemetry/scale_repository.dart';
import 'package:espresso_log/domain/telemetry/tare_event.dart';
import 'package:espresso_log/domain/telemetry/weight_reading.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'weight_change_state.dart';

class WeightChangeCubit extends Cubit<WeightChangeState> {
  final ScaleRepository _scaleRepository;
  final List<WeightReading> _history = [];
  WeightChangeCubit(this._scaleRepository) : super(WeightChangeInitial()) {
    _scaleRepository.stream.listen((event) {
      // remove event occured before taring
      if (event is TareEvent) {
        _history.removeWhere(
          (element) => element.timeStamp.isBefore(event.timeStamp),
        );
        return;
      }

      if (event is WeightReading == false) return;

      // cleanup history
      var removeBefore = event.timeStamp.subtract(
        const Duration(milliseconds: 600),
      );
      _history.removeWhere(
        (element) => element.timeStamp.isBefore(removeBefore),
      );

      // add to history
      _history.add(event as WeightReading);

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
