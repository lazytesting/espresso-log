import 'dart:io';

import 'package:espresso_log/services/scale/abstract_scale_service.dart';
import 'package:espresso_log/services/scale/weight_notification.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:rxdart/rxdart.dart';

class DecentScaleService implements AbstractScaleService {
  BluetoothDevice? _device; // TODO get this out of class, move to init
  BluetoothCharacteristic? _writeCharacteristic;
  BluetoothCharacteristic? _readCharacteristic;
  @override
  final weightNotificationController = BehaviorSubject<WeightNotification>();
  final scaleStatusController = BehaviorSubject<String>();

  @override
  Future<void> init() async {
    scaleStatusController.add("checking Bluetooth");
    await _ensureBluethooth();
    scaleStatusController.add("scanning");
    await _scanForDevice();
    scaleStatusController.add("connecting to scale");
    await _connectDevice();
    await _setCharacteristics();
    scaleStatusController.add("start listening");
    await _subscribeToReadings();
    await tareCommand();
  }

  Future<void> _ensureBluethooth() async {
    if (await FlutterBluePlus.isSupported == false) {
      print("Bluetooth not supported by this device");
      return;
    }

    var subscription =
        FlutterBluePlus.adapterState.listen((BluetoothAdapterState state) {
      print(state);
      if (state == BluetoothAdapterState.on) {
        // usually start scanning, connecting, etc
      } else {
        // show an error to the user, etc
      }
    });

    if (Platform.isAndroid) {
      await FlutterBluePlus.turnOn();
    }

    subscription.cancel();
  }

  Future<void> _scanForDevice() async {
    var subscription = FlutterBluePlus.onScanResults.listen(
      (results) {
        if (results.isNotEmpty) {
          ScanResult r = results.last; // the most recently found device
          _device = r.device;
          print('${r.device.remoteId}: "${r.device.platformName}" found!');
        }
      },
      onError: (e) => print(e),
    );
    FlutterBluePlus.cancelWhenScanComplete(subscription);

    await FlutterBluePlus.adapterState
        .where((val) => val == BluetoothAdapterState.on)
        .first;

    await FlutterBluePlus.startScan(
        withNames: ["Decent Scale"], timeout: Duration(seconds: 15));

    await FlutterBluePlus.isScanning.where((val) => val == false).first;
  }

  Future<void> _connectDevice() async {
    if (_device == null) {
      return;
    }
    var subscription =
        _device!.connectionState.listen((BluetoothConnectionState state) async {
      if (state == BluetoothConnectionState.disconnected) {
        // TODO:retry
      }
    });

    _device!.cancelWhenDisconnected(subscription, delayed: true, next: true);
    await _device!.connect();
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
  }

  Future<void> _subscribeToReadings() async {
    // todo figure out negative weight
    final subscription = _readCharacteristic!.onValueReceived.listen((value) {
      var decaGrams = (value[2] * 256) + value[3];
      var grams = decaGrams / 10;

      var isStable = value[1] == 0xCE;
      var minutesSinceOn = value[4];
      var secondsSinceOn = value[5];
      var millisSinceOn = value[6];
      var totalMillisSinceOn =
          (minutesSinceOn * 60 * 1000) + secondsSinceOn * 1000 + millisSinceOn;
      // TODO: check received time vs message time
      var notification = WeightNotification(
          weight: grams, isStable: isStable, timeStamp: DateTime.now());
      // ignore: avoid_print
      print("reading ${notification.weight}");
      weightNotificationController.add(notification);
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
