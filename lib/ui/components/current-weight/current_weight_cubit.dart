// lib/ui/components/current-weight/current_weight_cubit.dart
import 'package:equatable/equatable.dart';
import 'package:espresso_log/domain/telemetry/scale_repository.dart';
import 'package:espresso_log/domain/telemetry/weight_reading.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'current_weight_state.dart';

class CurrentWeightCubit extends Cubit<CurrentWeightState> {
  final ScaleRepository _scaleRepository;

  CurrentWeightCubit(this._scaleRepository) : super(CurrentWeightInitial()) {
    _scaleRepository.stream.listen((event) {
      if (event is WeightReading) {
        emit(CurrentWeightMeasured(event.weight));
      }
    });
  }
}
