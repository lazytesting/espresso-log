import 'package:espresso_log/services/scale/abstract_scale_service.dart';
import 'package:espresso_log/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'current_weight_state.dart';

class CurrentWeightCubit extends Cubit<CurrentWeightState> {
  final AbstractScaleService _scaleService = getIt.get<AbstractScaleService>();
  CurrentWeightCubit() : super(CurrentWeightInitial()) {
    _scaleService.weightNotificationController.stream.listen((event) {
      emit(CurrentWeightMeasured(event.weight));
    });
  }

  Future<void> tareScale() async {
    await _scaleService.tareCommand();
    emit(CurrentWeightInitial());
  }
}
