import 'package:espresso_log/devices/models/batter_device_mixin.dart';
import 'package:espresso_log/devices/pressure/models/abstract_pressure_service.dart';
import 'package:espresso_log/devices/scale/models/abstract_scale_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'connection_state.dart';

class ConnectionCubit extends Cubit<ConnectionState> {
  ConnectionCubit(this._scaleService, this._pressureService)
    : super(ConnectionConnecting());

  final AbstractScaleService _scaleService;
  final AbstractPressureService _pressureService;

  Future<void> reconnect() async {
    emit(ConnectionConnecting());
    if (_scaleService is BatteryDeviceMixin) {
      await (_scaleService as BatteryDeviceMixin).reconnect();
    }
    if (_pressureService is BatteryDeviceMixin) {
      await (_pressureService as BatteryDeviceMixin).reconnect();
    }
    emit(ConnectionEstablished());
  }

  Future<void> disconnect() async {
    if (_scaleService is BatteryDeviceMixin ||
        _pressureService is BatteryDeviceMixin) {
      emit(ConnectionPaused());
    }

    if (_scaleService is BatteryDeviceMixin) {
      await (_scaleService as BatteryDeviceMixin).disconnect();
    }
    if (_pressureService is BatteryDeviceMixin) {
      await (_pressureService as BatteryDeviceMixin).disconnect();
    }
  }

  Future<void> connect() async {
    emit(ConnectionConnecting());
    Future.wait([_scaleService.init(), _pressureService.init()]).then((_) {
      emit(ConnectionEstablished());
    });
  }
}
