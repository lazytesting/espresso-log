import 'dart:async';

import 'package:espresso_log/devices/models/batter_device_mixin.dart';
import 'package:espresso_log/devices/pressure/models/abstract_pressure_service.dart';
import 'package:espresso_log/devices/scale/models/abstract_scale_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class LoadingManager {
  final ValueNotifier<LoadingState> valueListenable =
      ValueNotifier<LoadingState>(LoadingState.connecting);
  final AbstractScaleService _scaleService;
  final AbstractPressureService _pressureService;

  LoadingManager(this._scaleService, this._pressureService);

  Future<void> reconnect() async {
    valueListenable.value = LoadingState.connecting;
    if (_scaleService is BatteryDeviceMixin) {
      (_scaleService as BatteryDeviceMixin).reconnect();
    }
    if (_pressureService is BatteryDeviceMixin) {
      (_pressureService as BatteryDeviceMixin).reconnect();
    }
    valueListenable.value = LoadingState.connected;
  }

  Future<void> disconnect() async {
    if (_scaleService is BatteryDeviceMixin ||
        _pressureService is BatteryDeviceMixin) {
      valueListenable.value = LoadingState.paused;
    }

    if (_scaleService is BatteryDeviceMixin) {
      (_scaleService as BatteryDeviceMixin).disconnect();
    }
    if (_pressureService is BatteryDeviceMixin) {
      (_pressureService as BatteryDeviceMixin).disconnect();
    }
  }

  Future<void> connect() async {
    valueListenable.value = LoadingState.connected;
    Future.wait([_scaleService.init(), _pressureService.init()]).then((_) {
      valueListenable.value = LoadingState.connected;
    });
  }
}

enum LoadingState { connecting, paused, connected }
