import 'dart:async';
import 'dart:typed_data';
import 'package:espresso_log/services/bluetooth/bluetooth_service.dart';
import 'package:espresso_log/services/pressure/abstract_pressure_service.dart';
import 'package:espresso_log/services/pressure/pressure_notification.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:logger/logger.dart';
import 'package:rxdart/subjects.dart';

class BookooPressureService implements AbstractPressureService {
  BookooPressureService(this._bluetoothService) {
    stream = _pressureNotificationController.stream.asBroadcastStream();
  }
  final BluetoothDevicesService _bluetoothService;
  final _pressureNotificationController =
      BehaviorSubject<PressureNotification>();
  @override
  Stream<PressureNotification> stream = const Stream.empty();
  BluetoothCharacteristic? _writeCharacteristic;
  BluetoothCharacteristic? _readCharacteristic;
  BluetoothDevice? _device;
  Logger logger = Logger();

  @override
  Future<void> init() async {
    _device = await _bluetoothService.connectToDevice("BOOKOO_EM");
    await _setCharacteristics();
    await _subscribeToReadings();
  }

  Future<void> _setCharacteristics() async {
    if (_device == null) {
      return;
    }
    List<BluetoothService> services = await _device!.discoverServices();
    List<BluetoothCharacteristic> chars = [];
    for (var s in services) {
      chars.addAll(s.characteristics);
    }

    // TODO debug and find correct guids
    _writeCharacteristic =
        chars.firstWhere((c) => c.characteristicUuid == Guid("FF01"));
    _readCharacteristic =
        chars.firstWhere((c) => c.characteristicUuid == Guid("FF02"));
  }

  Future<void> _sendCommand(List<int> value) async {
    _writeCharacteristic!.write(value);
  }

  Future<void> _subscribeToReadings() async {
    _sendCommand([0x02, 0x0c, 0x01, 0x00, 0x00, 0x00, 0x0f]);
    final subscription = _readCharacteristic!.onValueReceived.listen((value) {
      var d = ByteData(2);
      d.setInt8(0, value[4]);
      d.setInt8(1, value[5]);
      var pressure = d.getInt16(0) / 100;

      var notification = PressureNotification(pressure, DateTime.now());
      // ignore: avoid_print
      print("reading ${notification.pressure}");
      _pressureNotificationController.add(notification);
    });

    // cleanup: cancel subscription when disconnected
    _device!.cancelWhenDisconnected(subscription);

    // subscribe
    // Note: If a characteristic supports both **notifications** and **indications**,
    // it will default to **notifications**. This matches how CoreBluetooth works on iOS.
    await _readCharacteristic!.setNotifyValue(true);
  }

  @override
  void dispose() {
    //
  }
}
