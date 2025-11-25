import 'package:equatable/equatable.dart';
import 'package:espresso_log/devices/scale/models/abstract_scale_service.dart';
import 'package:espresso_log/devices/scale/models/weight_notification.dart';
import 'package:espresso_log/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'current_weight_state.dart';

class CurrentWeightCubit extends Cubit<CurrentWeightState> {
  final AbstractScaleService _scaleService = getIt.get<AbstractScaleService>();
  CurrentWeightCubit() : super(CurrentWeightInitial()) {
    _scaleService.stream.listen((event) {
      if (event is WeightNotification) {
        emit(CurrentWeightMeasured(event.weight));
      }
    });
  }
}
