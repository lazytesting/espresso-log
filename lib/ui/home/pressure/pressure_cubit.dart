import 'package:equatable/equatable.dart';
import 'package:espresso_log/services/pressure/abstract_pressure_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'pressure_state.dart';

class PressureCubit extends Cubit<PressureState> {
  final AbstractPressureService _pressureService;

  PressureCubit(this._pressureService) : super(PressureInitial()) {
    _pressureService.stream.listen((event) {
      emit(Pressure(event.pressure));
    });
  }
}
