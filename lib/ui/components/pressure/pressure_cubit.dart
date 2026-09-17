import 'package:equatable/equatable.dart';
import 'package:espresso_log/domain/telemetry/pressure_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'pressure_state.dart';

class PressureCubit extends Cubit<PressureState> {
  final PressureRepository _pressureRepository;

  PressureCubit(this._pressureRepository) : super(PressureInitial()) {
    _pressureRepository.stream.listen((event) {
      emit(Pressure(event.pressure));
    });
  }
}
