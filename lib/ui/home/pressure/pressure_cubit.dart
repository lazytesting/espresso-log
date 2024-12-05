import 'package:equatable/equatable.dart';
import 'package:espresso_log/main.dart';
import 'package:espresso_log/services/pressure/abstract_pressure_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'pressure_state.dart';

class PressureCubit extends Cubit<PressureState> {
  final AbstractPressureService _pressureService =
      getIt.get<AbstractPressureService>();

  PressureCubit() : super(PressureInitial()) {
    _pressureService.pressureNotificationController.listen((event) {
      emit(Pressure(event.pressure));
    });
  }
}
