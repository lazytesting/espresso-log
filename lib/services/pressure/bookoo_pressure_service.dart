import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:espresso_log/services/pressure/abstract_pressure_service.dart';
import 'package:espresso_log/services/pressure/pressure_notification.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:logger/logger.dart';
import 'package:rxdart/subjects.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BookooPressureService implements AbstractPressureService {
  BookooPressureService() {
    stream = _pressureNotificationController.stream.asBroadcastStream();
  }

  final _pressureNotificationController =
      BehaviorSubject<PressureNotification>();
  @override
  Stream<PressureNotification> stream = const Stream.empty();
  final pressureStatusController = BehaviorSubject<String>();
  BluetoothCharacteristic? _writeCharacteristic;
  BluetoothCharacteristic? _readCharacteristic;
  BluetoothDevice? _device;
  Logger logger = Logger();

  @override
  Future<void> init() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    pressureStatusController.add("checking Bluetooth");
    await _ensureBluethooth();
    final String? storedDeviceId = prefs.getString('pressureId');
    if (storedDeviceId == null) {
      pressureStatusController.add("scanning for new device");
      await _scanForDevice();
    } else {
      pressureStatusController.add("user stored device");
      _device = BluetoothDevice.fromId(storedDeviceId);
    }
    pressureStatusController.add("connecting to scale");
    await _connectDevice();
    await _setCharacteristics();
    pressureStatusController.add("start listening");
    await _subscribeToReadings();
    pressureStatusController.add("ready");
    await prefs.setString('scaleId', _device!.remoteId.toString());
  }

  // TODO make generic
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
          logger.d('${r.device.remoteId}: "${r.device.platformName}" found!');
          if (r.advertisementData.advName.startsWith("BOOKOO_EM")) {
            _device = r.device;
            FlutterBluePlus.stopScan();
          }
        }
      },
      onError: (e) => logger.e(e),
    );
    FlutterBluePlus.cancelWhenScanComplete(subscription);

    await FlutterBluePlus.adapterState
        .where((val) => val == BluetoothAdapterState.on)
        .first;

    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 45));

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
