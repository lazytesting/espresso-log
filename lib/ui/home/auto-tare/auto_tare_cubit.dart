import 'package:espresso_log/services/auto-tare/auto_tare_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../main.dart';

part 'auto_tare_state.dart';

class AutoTareCubit extends Cubit<AutoTareState> {
  AutoTareCubit() : super(AutoTareDisabledState());
  final AbstractAutoTare _autoTareService = getIt.get<AbstractAutoTare>();

  // TODO only actually enable when timer is running
  Future<void> enable() async {
    _autoTareService.start();
    emit(AutoTareEnabledState());
  }

  Future<void> disable() async {
    _autoTareService.stop();
    emit(AutoTareDisabledState());
  }
}
