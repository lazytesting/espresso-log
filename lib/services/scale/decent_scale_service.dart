import 'dart:typed_data';
import 'package:espresso_log/services/bluetooth/bluetooth_service.dart';
import 'package:espresso_log/services/notification.dart';
import 'package:espresso_log/services/scale/abstract_scale_service.dart';
import 'package:espresso_log/services/scale/weight_notification.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:rxdart/rxdart.dart';

class DecentScaleService implements AbstractScaleService {
  BluetoothDevice? _device; // TODO get this out of class, move to init
  BluetoothCharacteristic? _writeCharacteristic;
  BluetoothCharacteristic? _readCharacteristic;
  @override
  Stream<Notification> stream = const Stream.empty();

  final _scaleNotificationController = BehaviorSubject<Notification>();
  final scaleStatusController = BehaviorSubject<String>();

  DecentScaleService(this._bluetoothService) {
    stream = _scaleNotificationController.stream.asBroadcastStream();
  }

  final BluetoothDevicesService _bluetoothService;

  @override
  Future<void> init() async {
    _device = await _bluetoothService.connectToDevice("Decent Scale");
    await _setCharacteristics();
    await _subscribeToReadings();
    await tareCommand();
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

    _writeCharacteristic = chars.firstWhere((c) =>
        c.characteristicUuid == Guid("000036F5-0000-1000-8000-00805F9B34FB"));
    _readCharacteristic = chars.firstWhere((c) =>
        c.characteristicUuid == Guid("0000FFF4-0000-1000-8000-00805F9B34FB"));
  }

  Future<void> _sendCommand(List<int> value) async {
    _writeCharacteristic!.write(value);
  }

  @override
  Future<void> tareCommand() async {
    int incremental = 0x00; // todo increment
    List<int> command = [0x03, 0x0F, incremental, 0x00, 0x00, 0x00];
    List<int> signedCommand = _signWithXor(command);
    await _sendCommand(signedCommand);
    _scaleNotificationController
        .add(TareNotification(timeStamp: DateTime.now()));
  }

  Future<void> _subscribeToReadings() async {
    final subscription = _readCharacteristic!.onValueReceived.listen((value) {
      var d = ByteData(2);
      d.setInt8(0, value[2]);
      d.setInt8(1, value[3]);
      var grams = d.getInt16(0) / 10;

      // TODO: check received time vs message time
      var notification =
          WeightNotification(weight: grams, timeStamp: DateTime.now());
      // ignore: avoid_print
      print("reading ${notification.weight}");
      _scaleNotificationController.add(notification);
    });

    // cleanup: cancel subscription when disconnected
    _device!.cancelWhenDisconnected(subscription);

    // subscribe
    // Note: If a characteristic supports both **notifications** and **indications**,
    // it will default to **notifications**. This matches how CoreBluetooth works on iOS.
    await _readCharacteristic!.setNotifyValue(true);
  }

  List<int> _signWithXor(List<int> input) {
    int xorSign = input.first;
    for (int i = 1; i < input.length; i++) {
      xorSign ^= input[i]; // XOR operation with each element
    }

    input.add(xorSign);
    return input;
  }
}
