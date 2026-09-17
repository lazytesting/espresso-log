import 'dart:typed_data';
import 'package:espresso_log/data/bluetooth/bluetooth_devices_service.dart';
import 'package:espresso_log/domain/telemetry/scale_event.dart';
import 'package:espresso_log/domain/telemetry/scale_repository.dart';
import 'package:espresso_log/domain/telemetry/tare_event.dart';
import 'package:espresso_log/domain/telemetry/weight_reading.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:rxdart/rxdart.dart';
import 'package:talker_flutter/talker_flutter.dart';

class DecentScaleService implements ScaleRepository {
  BluetoothDevice? _device; // TODO get this out of class, move to init
  BluetoothCharacteristic? _writeCharacteristic;
  BluetoothCharacteristic? _readCharacteristic;
  @override
  Stream<ScaleEvent> stream = const Stream.empty();

  final _scaleEventController = BehaviorSubject<ScaleEvent>();
  final scaleStatusController = BehaviorSubject<String>();
  final Talker _talker;
  DecentScaleService(this._bluetoothService, this._talker) {
    stream = _scaleEventController.stream.asBroadcastStream();
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

    _writeCharacteristic = chars.firstWhere(
      (c) =>
          c.characteristicUuid == Guid("000036F5-0000-1000-8000-00805F9B34FB"),
    );
    _readCharacteristic = chars.firstWhere(
      (c) =>
          c.characteristicUuid == Guid("0000FFF4-0000-1000-8000-00805F9B34FB"),
    );
  }

  Future<void> _sendCommand(List<int> value) async {
    await _writeCharacteristic!.write(value);
  }

  @override
  Future<void> tareCommand() async {
    _talker.debug("Sending tare command to Decent Scale");
    int incremental = 0x00;
    List<int> command = [0x03, 0x0F, incremental, 0x00, 0x00, 0x00];
    List<int> signedCommand = _signWithXor(command);
    await _sendCommand(signedCommand);
  }

  Future<void> _subscribeToReadings() async {
    final subscription = _readCharacteristic!.onValueReceived.listen((value) {
      if (value.length < 2) {
        _talker.warning(
          "Ignoring malformed Decent Scale notification (too short): $value",
        );
        return;
      }

      // weight notifications
      if (value[1] == 0xCE || value[1] == 0xCA) {
        if (value.length < 4) {
          _talker.warning(
            "Ignoring malformed Decent Scale weight notification: $value",
          );
          return;
        }
        var d = ByteData(2);
        d.setInt8(0, value[2]);
        d.setInt8(1, value[3]);
        var grams = d.getInt16(0) / 10;

        var reading = WeightReading(weight: grams, timeStamp: DateTime.now());
        _talker.debug("Received weight event: ${reading.weight}");
        return _scaleEventController.add(reading);
      }

      // tare confirmation
      if (value[1] == 0x0F) {
        _talker.debug("Received tare confirmation");
        var event = TareEvent(timeStamp: DateTime.now());
        return _scaleEventController.add(event);
      }
    }, onError: (Object error, StackTrace stackTrace) {
      _talker.handle(
        error,
        stackTrace,
        "Error reading from Decent Scale characteristic",
      );
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
