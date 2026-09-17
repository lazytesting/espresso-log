import 'package:espresso_log/data/models/battery_device_mixin.dart';
import 'package:espresso_log/domain/telemetry/pressure_repository.dart';
import 'package:espresso_log/domain/telemetry/scale_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'connection_state.dart';

class ConnectionCubit extends Cubit<ConnectionState> {
  ConnectionCubit(this._scaleRepository, this._pressureRepository)
    : super(ConnectionConnecting());

  final ScaleRepository _scaleRepository;
  final PressureRepository _pressureRepository;

  Future<void> reconnect() async {
    emit(ConnectionConnecting());
    if (_scaleRepository is BatteryDeviceMixin) {
      await (_scaleRepository as BatteryDeviceMixin).reconnect();
    }
    if (_pressureRepository is BatteryDeviceMixin) {
      await (_pressureRepository as BatteryDeviceMixin).reconnect();
    }
    emit(ConnectionEstablished());
  }

  Future<void> disconnect() async {
    if (_scaleRepository is BatteryDeviceMixin ||
        _pressureRepository is BatteryDeviceMixin) {
      emit(ConnectionPaused());
    }

    if (_scaleRepository is BatteryDeviceMixin) {
      await (_scaleRepository as BatteryDeviceMixin).disconnect();
    }
    if (_pressureRepository is BatteryDeviceMixin) {
      await (_pressureRepository as BatteryDeviceMixin).disconnect();
    }
  }

  Future<void> connect() async {
    emit(ConnectionConnecting());
    Future.wait([_scaleRepository.init(), _pressureRepository.init()]).then((
      _,
    ) {
      emit(ConnectionEstablished());
    });
  }
}
