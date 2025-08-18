import 'dart:async';
import 'dart:io';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BluetoothDevicesService {
  Logger logger = Logger();

  Future<void> init() async {
    await _ensureBluethooth();
  }

  Future<BluetoothDevice> connectToDevice(String searchName) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? storedDeviceId = prefs.getString(searchName);

    // device already stored
    if (storedDeviceId != null) {
      return BluetoothDevice.fromId(storedDeviceId);
    }

    // use existing scanResults if possible
    var scanResults = FlutterBluePlus.lastScanResults
        .where((sr) => sr.advertisementData.advName.startsWith(searchName));

    if (scanResults.isNotEmpty) {
      await _connect(scanResults.first.device);
      return scanResults.first.device;
    }

    // trigger scan if not yet running
    if (!FlutterBluePlus.isScanningNow) {
      _scanForDevices();
    }

    // wait for the first scanResult with a match
    var scanResults2 = await FlutterBluePlus.scanResults.firstWhere(
        (result) => result.isNotEmpty &&
            result.last.advertisementData.advName.startsWith(searchName));
    var scanResult2 = scanResults2.firstWhere(
        (sr) => sr.advertisementData.advName.startsWith(searchName));
    await _connect(scanResult2.device);
    return scanResult2.device;
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

  Future<void> _scanForDevices() async {
    await FlutterBluePlus.adapterState
        .where((val) => val == BluetoothAdapterState.on)
        .first;

    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 45));

    // await FlutterBluePlus.isScanning.where((val) => val == false).first;
  }

  Future<void> _connect(BluetoothDevice device) async {
    var subscription =
        device.connectionState.listen((BluetoothConnectionState state) async {
      if (state == BluetoothConnectionState.disconnected) {
        // TODO:retry
      }
    });

    device.cancelWhenDisconnected(subscription, delayed: true, next: true);
    await device.connect();
  }
}
