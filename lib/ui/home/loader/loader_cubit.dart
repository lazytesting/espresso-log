import 'package:espresso_log/services/pressure/abstract_pressure_service.dart';
import 'package:espresso_log/services/scale/abstract_scale_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'loader_state.dart';

class LoaderCubit extends Cubit<LoaderState> {
  final AbstractScaleService _scaleService;
  final AbstractPressureService _pressureService;

  LoaderCubit(this._scaleService, this._pressureService)
    : super(LoaderInitial());

  void load() {
    Future.microtask(() => _load());
  }

  Future<void> _load() async {
    Future.wait([_scaleService.init(), _pressureService.init()]).then((_) {
      emit(LoaderCompleted());
    });
  }
}
