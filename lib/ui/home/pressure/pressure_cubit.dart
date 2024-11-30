import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:espresso_log/main.dart';
import 'package:espresso_log/services/pressure/abstract_pressure_service.dart';
import 'package:espresso_log/services/pressure/pressure_notification.dart';
import 'package:espresso_log/services/timer/abstract_timer_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'pressure_state.dart';

class PressureCubit extends Cubit<PressureState> {
  final AbstractPressureService _pressureService =
      getIt.get<AbstractPressureService>();
  late StreamSubscription<PressureNotification>
      _pressureNotificationSubscription;

  PressureCubit() : super(PressureInitial()) {
    _pressureService.pressureNotificationController.listen((event) {
      emit(Pressure(event.pressure));
    });
  }
}
