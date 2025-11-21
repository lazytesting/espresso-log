// disconnects battery powered devices after a period of inactivity
import 'dart:async';

import 'package:espresso_log/services/notification.dart';
import 'package:espresso_log/services/pressure/abstract_pressure_service.dart';
import 'package:espresso_log/services/scale/abstract_scale_service.dart';
import 'package:espresso_log/services/scale/weight_notification.dart';
import 'package:rxdart/transformers.dart';

class AutoDisconnectService {
  final AbstractScaleService _scaleService;
  final AbstractPressureService _pressureService;
  StreamSubscription<Notification>? _scaleSubscription;
  StreamSubscription<Notification>? _pressureSubscription;

  AutoDisconnectService(
    AbstractScaleService scaleService,
    AbstractPressureService pressureService,
  ) : _scaleService = scaleService,
      _pressureService = pressureService {
    _scaleService.stream
        .whereType<WeightNotification>()
        .map((wn) => wn.weight)
        .distinct();
  }

  // listen to scale events
  // listen to pressure events
  // if no event for 2 minutes, disconnect all battery powered devices

  void reconnect() {}
}


// Add mixin battery powered device
// add this to the bookoo pressure device

// listen to scale and pressure events
// if no event for 2 minutes, disconnect all battery powered devices

// method to re-enable