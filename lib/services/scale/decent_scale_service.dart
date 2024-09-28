import 'dart:io';

import 'package:espresso_log/services/scale/abstract_scale_service.dart';
import 'package:espresso_log/services/scale/weight_notification.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:logger/logger.dart';
import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DecentScaleService implements AbstractScaleService {
  BluetoothDevice? _device; // TODO get this out of class, move to init
  BluetoothCharacteristic? _writeCharacteristic;
  BluetoothCharacteristic? _readCharacteristic;
  Logger logger = Logger();

  @override
  final scaleNotificationController = BehaviorSubject<ScaleNotification>();
  final scaleStatusController = BehaviorSubject<String>();

  @override
  Future<void> init() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    scaleStatusController.add("checking Bluetooth");
    await _ensureBluethooth();
    final String? storedDeviceId = prefs.getString('scaleId');
    if (storedDeviceId == null) {
      scaleStatusController.add("scanning for new device");
      await _scanForDevice();
    } else {
      scaleStatusController.add("user stored device");
      _device = BluetoothDevice.fromId(storedDeviceId);
    }
    scaleStatusController.add("connecting to scale");
    await _connectDevice();
    await _setCharacteristics();
    scaleStatusController.add("start listening");
    await _subscribeToReadings();
    await tareCommand();
    scaleStatusController.add("ready");
    await prefs.setString('scaleId', _device!.remoteId.toString());
  }

  Future<void> _ensureBluethooth() async {
    if (await FlutterBluePlus.isSupported == false) {
      logger.d("Bluetooth not supported by this device");
      return;
    }

    var subscription =
        FlutterBluePlus.adapterState.listen((BluetoothAdapterState state) {
      logger.d(state);
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
          logger.d('${r.device.remoteId}: "${r.device.platformName}" found!');
        }
      },
      onError: (e) => logger.e(e),
    );
    FlutterBluePlus.cancelWhenScanComplete(subscription);

    await FlutterBluePlus.adapterState
        .where((val) => val == BluetoothAdapterState.on)
        .first;

    await FlutterBluePlus.startScan(
        withNames: ["Decent Scale"], timeout: const Duration(seconds: 15));

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
    scaleNotificationController
        .add(TareNotification(timeStamp: DateTime.now()));
  }

  Future<void> _subscribeToReadings() async {
    final subscription = _readCharacteristic!.onValueReceived.listen((value) {
      var decaGrams = (value[2] * 256) + value[3];

      // if above 3200 gram it is actually a negative weight
      // TODO: negative weight is still off a bit
      if (decaGrams > 32000) {
        var signed2 = value[2].toSigned(8);
        var signed3 = value[3].toSigned(8);
        decaGrams = (signed2 * 256) + signed3;
      }

      var grams = decaGrams / 10;
      // TODO: check received time vs message time
      var notification =
          WeightNotification(weight: grams, timeStamp: DateTime.now());
      // ignore: avoid_print
      print("reading ${notification.weight}");
      scaleNotificationController.add(notification);
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
