# Domain Layer Refactor Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Introduce an explicit, framework-free domain layer (value objects, repository interfaces, domain rules) under `lib/domain/`, move device adapters to `lib/data/`, and thin `ShotGraphCubit` down to orchestration by extracting its accumulation/tare-zeroing logic into a new, independently-tested `ShotRecordingSession`.

**Architecture:** MVVM with Ports-and-Adapters underneath. Domain defines `*Repository` interfaces for anything backed by external infrastructure (Scale, Pressure) and plain `Abstract*` interfaces for internal test-substitutability seams (ShotClock, the two domain rules). Data implements the repositories. Cubits (ViewModels) depend only on domain types and never contain business logic themselves.

**Tech Stack:** Flutter/Dart (FVM-pinned, see `.fvmrc`), `flutter_bloc` (Cubit), `mockito` + `build_runner` for test doubles, `rxdart` for stream simulation in tests.

**Spec:** [docs/superpowers/specs/2026-09-17-domain-layer-refactor.md](../specs/2026-09-17-domain-layer-refactor.md)

## Global Constraints

- No new dependencies added to `pubspec.yaml`.
- No behavior changes except the one documented in the spec's "Explicitly not changing" section (the `ShotRecordingSession.stop()` vs `.reset()` split).
- Every task must leave `fvm flutter analyze` clean for the files it touches and `fvm flutter test` green for the tests it touches. The whole-project `fvm flutter analyze`/`fvm flutter test` only needs to be clean starting at Task 17 (once every consumer has been rewired) and must be verified in Task 18.
- Preserve existing lints (`package:flutter_lints/flutter.yaml`, see `analysis_options.yaml`) — no lint suppressions introduced.
- Commit after every task, using the existing repo's plain conventional-ish one-line commit style (see `git log`).

---

## Task 1: Scale telemetry events — `ScaleEvent`, `WeightReading`, `TareEvent`

**Files:**
- Create: `lib/domain/telemetry/scale_event.dart`
- Create: `lib/domain/telemetry/weight_reading.dart`
- Create: `lib/domain/telemetry/tare_event.dart`
- Test: `test/domain/telemetry/scale_event_test.dart`

**Interfaces:**
- Produces: `abstract class ScaleEvent { DateTime get timeStamp; Map<String, dynamic> toJson(); }`; `class WeightReading implements ScaleEvent` with `final double weight`, constructor `WeightReading({required double weight, required DateTime timeStamp})`; `class TareEvent implements ScaleEvent` with constructor `TareEvent({required DateTime timeStamp})`.

- [ ] **Step 1: Write the failing test**

```dart
// test/domain/telemetry/scale_event_test.dart
import 'package:espresso_log/domain/telemetry/scale_event.dart';
import 'package:espresso_log/domain/telemetry/tare_event.dart';
import 'package:espresso_log/domain/telemetry/weight_reading.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('WeightReading serializes to json with its weight', () {
    final timeStamp = DateTime(2026, 1, 1, 10, 0);
    final ScaleEvent event = WeightReading(weight: 42.5, timeStamp: timeStamp);

    expect(event.toJson(), {
      'type': 'WeightReading',
      'weight': 42.5,
      'timeStamp': timeStamp.toIso8601String(),
    });
  });

  test('TareEvent serializes to json without a weight field', () {
    final timeStamp = DateTime(2026, 1, 1, 10, 0, 5);
    final ScaleEvent event = TareEvent(timeStamp: timeStamp);

    expect(event.toJson(), {
      'type': 'TareEvent',
      'timeStamp': timeStamp.toIso8601String(),
    });
  });

  test('both event types are assignable to the shared ScaleEvent type', () {
    final List<ScaleEvent> events = [
      WeightReading(weight: 1, timeStamp: DateTime(2026)),
      TareEvent(timeStamp: DateTime(2026)),
    ];

    expect(events, hasLength(2));
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `fvm flutter test test/domain/telemetry/scale_event_test.dart -v`
Expected: FAIL — `lib/domain/telemetry/scale_event.dart` (and siblings) don't exist yet.

- [ ] **Step 3: Write the implementation**

```dart
// lib/domain/telemetry/scale_event.dart
abstract class ScaleEvent {
  DateTime get timeStamp;

  Map<String, dynamic> toJson();
}
```

```dart
// lib/domain/telemetry/weight_reading.dart
import 'package:espresso_log/domain/telemetry/scale_event.dart';

class WeightReading implements ScaleEvent {
  final double weight;
  @override
  final DateTime timeStamp;

  WeightReading({required this.weight, required this.timeStamp});

  @override
  Map<String, dynamic> toJson() => {
    'type': 'WeightReading',
    'weight': weight,
    'timeStamp': timeStamp.toIso8601String(),
  };
}
```

```dart
// lib/domain/telemetry/tare_event.dart
import 'package:espresso_log/domain/telemetry/scale_event.dart';

class TareEvent implements ScaleEvent {
  @override
  final DateTime timeStamp;

  TareEvent({required this.timeStamp});

  @override
  Map<String, dynamic> toJson() => {
    'type': 'TareEvent',
    'timeStamp': timeStamp.toIso8601String(),
  };
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `fvm flutter test test/domain/telemetry/scale_event_test.dart -v`
Expected: PASS (3 tests)

- [ ] **Step 5: Commit**

```bash
git add lib/domain/telemetry/scale_event.dart lib/domain/telemetry/weight_reading.dart lib/domain/telemetry/tare_event.dart test/domain/telemetry/scale_event_test.dart
git commit -m "domain: add ScaleEvent, WeightReading, TareEvent"
```

---

## Task 2: Pressure telemetry — `PressureReading`

**Files:**
- Create: `lib/domain/telemetry/pressure_reading.dart`
- Test: `test/domain/telemetry/pressure_reading_test.dart`

**Interfaces:**
- Produces: `class PressureReading` with `final double pressure`, `final DateTime timeStamp`, constructor `PressureReading(double pressure, DateTime timeStamp)`, `Map<String, dynamic> toJson()`.

- [ ] **Step 1: Write the failing test**

```dart
// test/domain/telemetry/pressure_reading_test.dart
import 'package:espresso_log/domain/telemetry/pressure_reading.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('PressureReading serializes to json', () {
    final timeStamp = DateTime(2026, 1, 1, 10, 0);
    final reading = PressureReading(8.4, timeStamp);

    expect(reading.toJson(), {
      'type': 'PressureReading',
      'pressure': 8.4,
      'timeStamp': timeStamp.toIso8601String(),
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `fvm flutter test test/domain/telemetry/pressure_reading_test.dart -v`
Expected: FAIL — file doesn't exist.

- [ ] **Step 3: Write the implementation**

```dart
// lib/domain/telemetry/pressure_reading.dart
class PressureReading {
  final double pressure;
  final DateTime timeStamp;

  PressureReading(this.pressure, this.timeStamp);

  Map<String, dynamic> toJson() => {
    'type': 'PressureReading',
    'pressure': pressure,
    'timeStamp': timeStamp.toIso8601String(),
  };
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `fvm flutter test test/domain/telemetry/pressure_reading_test.dart -v`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/domain/telemetry/pressure_reading.dart test/domain/telemetry/pressure_reading_test.dart
git commit -m "domain: add PressureReading"
```

---

## Task 3: Shot timer events — `TimerEvent`, `TimerStarted`, `TimerTicked`, `TimerStopped`

**Files:**
- Create: `lib/domain/shot/timer_event.dart`
- Test: `test/domain/shot/timer_event_test.dart`

**Interfaces:**
- Produces: `abstract class TimerEvent { final DateTime timeStamp; final int milliSeconds; Map<String, dynamic> toJson(); }` and subclasses `TimerStarted`, `TimerTicked`, `TimerStopped`, each with constructor `(DateTime timeStamp, int milliSeconds)`.

- [ ] **Step 1: Write the failing test**

```dart
// test/domain/shot/timer_event_test.dart
import 'package:espresso_log/domain/shot/timer_event.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final timeStamp = DateTime(2026, 1, 1, 10, 0);

  test('TimerStarted serializes to json', () {
    final TimerEvent event = TimerStarted(timeStamp, 0);
    expect(event.toJson(), {
      'type': 'TimerStarted',
      'milliSeconds': 0,
      'timeStamp': timeStamp.toIso8601String(),
    });
  });

  test('TimerTicked serializes to json', () {
    final TimerEvent event = TimerTicked(timeStamp, 1500);
    expect(event.toJson(), {
      'type': 'TimerTicked',
      'milliSeconds': 1500,
      'timeStamp': timeStamp.toIso8601String(),
    });
  });

  test('TimerStopped serializes to json', () {
    final TimerEvent event = TimerStopped(timeStamp, 28000);
    expect(event.toJson(), {
      'type': 'TimerStopped',
      'milliSeconds': 28000,
      'timeStamp': timeStamp.toIso8601String(),
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `fvm flutter test test/domain/shot/timer_event_test.dart -v`
Expected: FAIL — file doesn't exist.

- [ ] **Step 3: Write the implementation**

```dart
// lib/domain/shot/timer_event.dart
abstract class TimerEvent {
  final DateTime timeStamp;
  final int milliSeconds;

  TimerEvent(this.timeStamp, this.milliSeconds);

  Map<String, dynamic> toJson();
}

class TimerStarted extends TimerEvent {
  TimerStarted(super.timeStamp, super.milliSeconds);

  @override
  Map<String, dynamic> toJson() => {
    'type': 'TimerStarted',
    'milliSeconds': milliSeconds,
    'timeStamp': timeStamp.toIso8601String(),
  };
}

class TimerTicked extends TimerEvent {
  TimerTicked(super.timeStamp, super.milliSeconds);

  @override
  Map<String, dynamic> toJson() => {
    'type': 'TimerTicked',
    'milliSeconds': milliSeconds,
    'timeStamp': timeStamp.toIso8601String(),
  };
}

class TimerStopped extends TimerEvent {
  TimerStopped(super.timeStamp, super.milliSeconds);

  @override
  Map<String, dynamic> toJson() => {
    'type': 'TimerStopped',
    'milliSeconds': milliSeconds,
    'timeStamp': timeStamp.toIso8601String(),
  };
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `fvm flutter test test/domain/shot/timer_event_test.dart -v`
Expected: PASS (3 tests)

- [ ] **Step 5: Commit**

```bash
git add lib/domain/shot/timer_event.dart test/domain/shot/timer_event_test.dart
git commit -m "domain: add TimerEvent hierarchy"
```

---

## Task 4: Repository interfaces — `ScaleRepository`, `PressureRepository`

**Files:**
- Create: `lib/domain/telemetry/scale_repository.dart`
- Create: `lib/domain/telemetry/pressure_repository.dart`

**Interfaces:**
- Consumes: `ScaleEvent` (Task 1), `PressureReading` (Task 2).
- Produces: `abstract class ScaleRepository { Stream<ScaleEvent> stream; Future<void> init(); Future<void> tareCommand(); }`; `abstract class PressureRepository { Stream<PressureReading> stream; Future<void> init(); void dispose(); }`.

No behavior to unit-test here (pure interface declarations, mirroring today's `AbstractScaleService`/`AbstractPressureService`) — correctness is verified by the compiler once adapters implement them in Tasks 7–8, and by `flutter analyze`.

- [ ] **Step 1: Write the interfaces**

```dart
// lib/domain/telemetry/scale_repository.dart
import 'package:espresso_log/domain/telemetry/scale_event.dart';

abstract class ScaleRepository {
  Stream<ScaleEvent> stream = const Stream.empty();

  Future<void> init() async {}

  Future<void> tareCommand() async {}
}
```

```dart
// lib/domain/telemetry/pressure_repository.dart
import 'package:espresso_log/domain/telemetry/pressure_reading.dart';

abstract class PressureRepository {
  Stream<PressureReading> stream = const Stream.empty();

  Future<void> init() async {}

  void dispose();
}
```

- [ ] **Step 2: Verify it compiles**

Run: `fvm flutter analyze lib/domain/telemetry/scale_repository.dart lib/domain/telemetry/pressure_repository.dart`
Expected: No issues found.

- [ ] **Step 3: Commit**

```bash
git add lib/domain/telemetry/scale_repository.dart lib/domain/telemetry/pressure_repository.dart
git commit -m "domain: add ScaleRepository and PressureRepository interfaces"
```

---

## Task 5: `AbstractShotClock`

**Files:**
- Create: `lib/domain/shot/abstract_shot_clock.dart`

**Interfaces:**
- Consumes: `TimerEvent` (Task 3).
- Produces: `abstract class AbstractShotClock { Stream<TimerEvent> stream; bool get isRunning; Future<void> start(); Future<void> stop(); }`.

- [ ] **Step 1: Write the interface**

```dart
// lib/domain/shot/abstract_shot_clock.dart
import 'package:espresso_log/domain/shot/timer_event.dart';

abstract class AbstractShotClock {
  Stream<TimerEvent> stream = const Stream.empty();
  bool get isRunning;

  Future<void> start() async {}

  Future<void> stop() async {}
}
```

- [ ] **Step 2: Verify it compiles**

Run: `fvm flutter analyze lib/domain/shot/abstract_shot_clock.dart`
Expected: No issues found.

- [ ] **Step 3: Commit**

```bash
git add lib/domain/shot/abstract_shot_clock.dart
git commit -m "domain: add AbstractShotClock interface"
```

---

## Task 6: Move `BluetoothDevicesService` and `BatteryDeviceMixin` to `lib/data/`

This is a pure relocation (plus fixing the existing `batter_device_mixin.dart` filename typo). Nothing in either file's logic changes. To keep the project compiling after this task, the four files that currently import them are updated in the same task — only their import lines, nothing else yet (their fuller retyping happens in Tasks 7, 8, 15, 16).

**Files:**
- Create: `lib/data/bluetooth/bluetooth_devices_service.dart` (moved from `lib/devices/bluetooth/bluetooth_service.dart`, unchanged content)
- Create: `lib/data/models/battery_device_mixin.dart` (moved from `lib/devices/models/batter_device_mixin.dart`, unchanged content, only the file/path spelling fixed)
- Delete: `lib/devices/bluetooth/bluetooth_service.dart`
- Delete: `lib/devices/models/batter_device_mixin.dart`
- Modify: `lib/devices/pressure/bookoo_pressure_service.dart` (import lines only)
- Modify: `lib/devices/pressure/mock_pressure_service.dart` (import line only)
- Modify: `lib/devices/scale/decent_scale_service.dart` (import line only)
- Modify: `lib/ui/home/device_connection/connection_cubit.dart` (import line only)
- Modify: `lib/main.dart` (import line only)

**Interfaces:**
- Produces: `class BluetoothDevicesService` (unchanged API) at its new import path `package:espresso_log/data/bluetooth/bluetooth_devices_service.dart`; `mixin BatteryDeviceMixin` (unchanged API) at `package:espresso_log/data/models/battery_device_mixin.dart`.

- [ ] **Step 1: Create the moved files with identical content**

```dart
// lib/data/bluetooth/bluetooth_devices_service.dart
import 'dart:async';
import 'dart:io';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talker_flutter/talker_flutter.dart' show Talker;

class BluetoothDevicesService {
  final Talker _talker;

  BluetoothDevicesService({required Talker talker}) : _talker = talker;

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
    var scanResults = FlutterBluePlus.lastScanResults.where(
      (sr) => sr.advertisementData.advName.startsWith(searchName),
    );

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
      (result) =>
          result.isNotEmpty &&
          result.last.advertisementData.advName.startsWith(searchName),
    );
    var scanResult2 = scanResults2.firstWhere(
      (sr) => sr.advertisementData.advName.startsWith(searchName),
    );
    await _connect(scanResult2.device);
    return scanResult2.device;
  }

  Future<void> _ensureBluethooth() async {
    if (await FlutterBluePlus.isSupported == false) {
      _talker.debug("Bluetooth not supported by this device");
      return;
    }

    var subscription = FlutterBluePlus.adapterState.listen((
      BluetoothAdapterState state,
    ) {
      _talker.debug(state);
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
    var subscription = device.connectionState.listen((
      BluetoothConnectionState state,
    ) async {
      if (state == BluetoothConnectionState.disconnected) {
        // TODO:retry
      }
    });

    device.cancelWhenDisconnected(subscription, delayed: true, next: true);
    await device.connect(license: License.free);
  }
}
```

```dart
// lib/data/models/battery_device_mixin.dart
mixin BatteryDeviceMixin {
  Future<void> reconnect();
  Future<void> disconnect();
}
```

- [ ] **Step 2: Delete the old files**

```bash
rm lib/devices/bluetooth/bluetooth_service.dart lib/devices/models/batter_device_mixin.dart
```

- [ ] **Step 3: Update the four import lines in dependent files**

In `lib/devices/pressure/bookoo_pressure_service.dart`, replace:
```dart
import 'package:espresso_log/devices/models/batter_device_mixin.dart';
```
with:
```dart
import 'package:espresso_log/data/models/battery_device_mixin.dart';
```
and replace:
```dart
import 'package:espresso_log/devices/bluetooth/bluetooth_service.dart';
```
with:
```dart
import 'package:espresso_log/data/bluetooth/bluetooth_devices_service.dart';
```

In `lib/devices/pressure/mock_pressure_service.dart`, replace:
```dart
import 'package:espresso_log/devices/models/batter_device_mixin.dart';
```
with:
```dart
import 'package:espresso_log/data/models/battery_device_mixin.dart';
```

In `lib/devices/scale/decent_scale_service.dart`, replace:
```dart
import 'package:espresso_log/devices/bluetooth/bluetooth_service.dart';
```
with:
```dart
import 'package:espresso_log/data/bluetooth/bluetooth_devices_service.dart';
```

In `lib/ui/home/device_connection/connection_cubit.dart`, replace:
```dart
import 'package:espresso_log/devices/models/batter_device_mixin.dart';
```
with:
```dart
import 'package:espresso_log/data/models/battery_device_mixin.dart';
```

In `lib/main.dart`, replace:
```dart
import 'devices/bluetooth/bluetooth_service.dart';
```
with:
```dart
import 'data/bluetooth/bluetooth_devices_service.dart';
```
(This file was missed from the original dependent-files list — it has a 5th reference to the moved file via a relative import plus a `BluetoothDevicesService(...)` constructor call at its existing usage site. Only this import line changes; every other stale reference in `main.dart`, e.g. to `AbstractScaleService`, is out of scope here and is Task 17's job.)

- [ ] **Step 4: Verify the project still analyzes clean**

Run: `fvm flutter analyze`
Expected: No issues found. (`BluetoothDevicesService` and `BatteryDeviceMixin` are otherwise unused-import-free at this point since only import lines changed, no call sites changed.)

- [ ] **Step 5: Commit**

```bash
git add lib/data/bluetooth/bluetooth_devices_service.dart lib/data/models/battery_device_mixin.dart lib/devices/bluetooth/bluetooth_service.dart lib/devices/models/batter_device_mixin.dart lib/devices/pressure/bookoo_pressure_service.dart lib/devices/pressure/mock_pressure_service.dart lib/devices/scale/decent_scale_service.dart lib/ui/home/device_connection/connection_cubit.dart lib/main.dart
git commit -m "data: move BluetoothDevicesService and BatteryDeviceMixin under lib/data"
```

---

## Task 7: Move and retype the scale adapters — `DecentScaleService`, `MockScaleService`

**Files:**
- Create: `lib/data/scale/decent_scale_service.dart`
- Create: `lib/data/scale/mock_scale_service.dart`
- Delete: `lib/devices/scale/decent_scale_service.dart`
- Delete: `lib/devices/scale/mock_scale_service.dart`

**Interfaces:**
- Consumes: `ScaleRepository` (Task 4), `ScaleEvent`/`WeightReading`/`TareEvent` (Task 1), `BluetoothDevicesService` (Task 6, already at its new path).
- Produces: `class DecentScaleService implements ScaleRepository`, `class MockScaleService implements ScaleRepository` — both at their new paths, same public API as today (`init()`, `tareCommand()`, `stream`).

These two classes contain BLE byte-parsing logic that can't be exercised without real hardware — there's no existing test for them today and this task doesn't add one; it's a straight move + type substitution. Correctness is verified by `flutter analyze` plus manual smoke-testing via `fvm flutter run --dart-define USE_MOCK_SCALE=true` after Task 17 rewires the Cubits that consume this.

- [ ] **Step 1: Create the moved, retyped files**

```dart
// lib/data/scale/decent_scale_service.dart
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
      // weight notifications
      if (value[1] == 0xCE || value[1] == 0xCA) {
        var d = ByteData(2);
        d.setInt8(0, value[2]);
        d.setInt8(1, value[3]);
        var grams = d.getInt16(0) / 10;

        var reading = WeightReading(weight: grams, timeStamp: DateTime.now());
        // ignore: avoid_print
        _talker.debug("Received weight event: ${reading.weight}");
        return _scaleEventController.add(reading);
      }

      // tare confirmation
      if (value[1] == 0x0F) {
        _talker.debug("Received tare confirmation");
        var event = TareEvent(timeStamp: DateTime.now());
        return _scaleEventController.add(event);
      }
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
```

```dart
// lib/data/scale/mock_scale_service.dart
import 'dart:async';
import 'dart:math';

import 'package:espresso_log/domain/telemetry/scale_event.dart';
import 'package:espresso_log/domain/telemetry/scale_repository.dart';
import 'package:espresso_log/domain/telemetry/tare_event.dart';
import 'package:espresso_log/domain/telemetry/weight_reading.dart';
import 'package:rxdart/rxdart.dart';

class MockScaleService implements ScaleRepository {
  final _scaleEventController = BehaviorSubject<ScaleEvent>();
  Timer? _timer;
  int _count = 0;
  @override
  Stream<ScaleEvent> stream = const Stream.empty();

  MockScaleService() {
    stream = _scaleEventController.stream.asBroadcastStream();
  }

  @override
  Future<void> init() async {
    _timer = Timer.periodic(const Duration(milliseconds: 200), (Timer t) {
      var weight = (_count / 5) + Random().nextDouble();
      if (t.tick >= 40 && t.tick <= 55) {
        weight = 52;
      }

      _scaleEventController.add(
        WeightReading(weight: weight, timeStamp: DateTime.now()),
      );
      _count++;
    });
  }

  @override
  Future<void> tareCommand() async {
    _scaleEventController.add(TareEvent(timeStamp: DateTime.now()));
    _count = 0;
  }

  void dispose() {
    _timer?.cancel();
  }
}
```

- [ ] **Step 2: Delete the old files**

```bash
rm lib/devices/scale/decent_scale_service.dart lib/devices/scale/mock_scale_service.dart
```

- [ ] **Step 3: Verify the new files compile in isolation**

Run: `fvm flutter analyze lib/data/scale/decent_scale_service.dart lib/data/scale/mock_scale_service.dart`
Expected: No issues found. (Whole-project analyze will still show errors from `lib/devices/scale/models/*.dart` and consumers still pointing at the old `AbstractScaleService` — that's expected until Tasks 8–17 land. Do not run whole-project `flutter analyze` as the pass/fail gate for this task.)

- [ ] **Step 4: Commit**

```bash
git add lib/data/scale/decent_scale_service.dart lib/data/scale/mock_scale_service.dart lib/devices/scale/decent_scale_service.dart lib/devices/scale/mock_scale_service.dart
git commit -m "data: move DecentScaleService and MockScaleService, implement ScaleRepository"
```

---

## Task 8: Move and retype the pressure adapters — `BookooPressureService`, `MockPressureService`

**Files:**
- Create: `lib/data/pressure/bookoo_pressure_service.dart`
- Create: `lib/data/pressure/mock_pressure_service.dart`
- Delete: `lib/devices/pressure/bookoo_pressure_service.dart`
- Delete: `lib/devices/pressure/mock_pressure_service.dart`

**Interfaces:**
- Consumes: `PressureRepository` (Task 4), `PressureReading` (Task 2), `BatteryDeviceMixin` (Task 6), `BluetoothDevicesService` (Task 6).
- Produces: `class BookooPressureService with BatteryDeviceMixin implements PressureRepository`, `class MockPressureService with BatteryDeviceMixin implements PressureRepository`.

Same rationale as Task 7 for not adding new tests here — BLE parsing, no existing coverage, straight move + type substitution.

- [ ] **Step 1: Create the moved, retyped files**

```dart
// lib/data/pressure/bookoo_pressure_service.dart
import 'dart:async';
import 'dart:typed_data';
import 'package:espresso_log/data/bluetooth/bluetooth_devices_service.dart';
import 'package:espresso_log/data/models/battery_device_mixin.dart';
import 'package:espresso_log/domain/telemetry/pressure_reading.dart';
import 'package:espresso_log/domain/telemetry/pressure_repository.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:rxdart/subjects.dart';
import 'package:talker_flutter/talker_flutter.dart';

class BookooPressureService with BatteryDeviceMixin implements PressureRepository {
  BookooPressureService(this._bluetoothService, this._talker) {
    stream = _pressureReadingController.stream.asBroadcastStream();
  }

  final Talker _talker;
  final BluetoothDevicesService _bluetoothService;
  final _pressureReadingController = BehaviorSubject<PressureReading>();
  @override
  Stream<PressureReading> stream = const Stream.empty();
  BluetoothCharacteristic? _writeCharacteristic;
  BluetoothCharacteristic? _readCharacteristic;
  BluetoothDevice? _device;

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

    _writeCharacteristic = chars.firstWhere(
      (c) => c.characteristicUuid == Guid("FF01"),
    );
    _readCharacteristic = chars.firstWhere(
      (c) => c.characteristicUuid == Guid("FF02"),
    );
    _talker.debug("Pressure characteristics set");
  }

  Future<void> _sendCommand(List<int> value) async {
    await _writeCharacteristic!.write(value);
  }

  Future<void> _subscribeToReadings() async {
    _talker.debug("Subscribing to pressure readings");
    await _sendCommand([0x02, 0x0c, 0x01, 0x00, 0x00, 0x00, 0x0f]);
    final subscription = _readCharacteristic!.onValueReceived.listen((value) {
      _talker.debug("Pressure data received $value");
      var d = ByteData(2);
      d.setInt8(0, value[4]);
      d.setInt8(1, value[5]);
      var pressure = d.getInt16(0) / 100;

      var reading = PressureReading(pressure, DateTime.now());
      _talker.debug("Emit pressure event: ${reading.pressure}");
      _pressureReadingController.add(reading);
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

  @override
  Future<void> reconnect() async {
    await init();
  }

  @override
  Future<void> disconnect() async {
    if (_device != null && _device!.isConnected) {
      await _device!.disconnect();
    }
  }
}
```

```dart
// lib/data/pressure/mock_pressure_service.dart
import 'dart:async';
import 'package:espresso_log/data/models/battery_device_mixin.dart';
import 'package:espresso_log/domain/telemetry/pressure_reading.dart';
import 'package:espresso_log/domain/telemetry/pressure_repository.dart';
import 'package:rxdart/subjects.dart';

class MockPressureService with BatteryDeviceMixin implements PressureRepository {
  MockPressureService() {
    stream = _pressureReadingController.stream.asBroadcastStream();
  }
  final _pressureReadingController = BehaviorSubject<PressureReading>();
  Timer? _timer;

  @override
  Stream<PressureReading> stream = const Stream.empty();

  @override
  Future<void> init() async {
    Future.delayed(Duration(seconds: 3));
    _timer = Timer.periodic(const Duration(milliseconds: 200), (Timer t) {
      double pressure = 0;
      var seconds = t.tick / 5;
      if (seconds > 10 && seconds <= 15) {
        pressure = seconds - 10;
      } else if (seconds > 15 && seconds <= 20) {
        pressure = 5 - (seconds - 15);
      } else if (seconds > 20 && seconds <= 350) {
        pressure = 8;
      }
      _pressureReadingController.asBroadcastStream();
      _pressureReadingController.add(PressureReading(pressure, DateTime.now()));
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
  }

  @override
  Future<void> disconnect() {
    return Future.delayed(Duration(seconds: 1));
  }

  @override
  Future<void> reconnect() {
    return Future.delayed(Duration(seconds: 1));
  }
}
```

- [ ] **Step 2: Delete the old files**

```bash
rm lib/devices/pressure/bookoo_pressure_service.dart lib/devices/pressure/mock_pressure_service.dart
```

- [ ] **Step 3: Verify the new files compile in isolation**

Run: `fvm flutter analyze lib/data/pressure/bookoo_pressure_service.dart lib/data/pressure/mock_pressure_service.dart`
Expected: No issues found.

- [ ] **Step 4: Commit**

```bash
git add lib/data/pressure/bookoo_pressure_service.dart lib/data/pressure/mock_pressure_service.dart lib/devices/pressure/bookoo_pressure_service.dart lib/devices/pressure/mock_pressure_service.dart
git commit -m "data: move BookooPressureService and MockPressureService, implement PressureRepository"
```

---

## Task 9: Move and rename `TimerService` → `ShotClock`

**Files:**
- Create: `lib/domain/shot/shot_clock.dart`
- Delete: `lib/devices/timer/timer_service.dart`
- Test: `test/domain/shot/shot_clock_test.dart`

**Interfaces:**
- Consumes: `AbstractShotClock` (Task 5), `TimerEvent`/`TimerStarted`/`TimerTicked`/`TimerStopped` (Task 3).
- Produces: `class ShotClock implements AbstractShotClock`.

There's no existing test for `TimerService` today. This task adds a first one covering the observable contract (`isRunning`, start/stop emit the right event types) since it's now cheap to test as a pure domain class with `fake_async`-free real timers on short durations.

- [ ] **Step 1: Write the failing test**

```dart
// test/domain/shot/shot_clock_test.dart
import 'package:espresso_log/domain/shot/shot_clock.dart';
import 'package:espresso_log/domain/shot/timer_event.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('isRunning is false before start and true after', () async {
    final clock = ShotClock();
    expect(clock.isRunning, isFalse);

    await clock.start();
    expect(clock.isRunning, isTrue);

    await clock.stop();
    expect(clock.isRunning, isFalse);
  });

  test('start emits a TimerStarted event with 0 milliseconds', () async {
    final clock = ShotClock();
    final events = <TimerEvent>[];
    clock.stream.listen(events.add);

    await clock.start();
    await pumpEventQueue();
    await clock.stop();

    expect(events.first, isA<TimerStarted>());
    expect(events.first.milliSeconds, 0);
  });

  test('stop emits a TimerStopped event', () async {
    final clock = ShotClock();
    final events = <TimerEvent>[];
    clock.stream.listen(events.add);

    await clock.start();
    await pumpEventQueue();
    await clock.stop();
    await pumpEventQueue();

    expect(events.last, isA<TimerStopped>());
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `fvm flutter test test/domain/shot/shot_clock_test.dart -v`
Expected: FAIL — `lib/domain/shot/shot_clock.dart` doesn't exist.

- [ ] **Step 3: Write the implementation**

```dart
// lib/domain/shot/shot_clock.dart
import 'dart:async';

import 'package:espresso_log/domain/shot/abstract_shot_clock.dart';
import 'package:espresso_log/domain/shot/timer_event.dart';
import 'package:rxdart/rxdart.dart';

class ShotClock implements AbstractShotClock {
  final _streamController = BehaviorSubject<TimerEvent>();
  @override
  Stream<TimerEvent> stream = const Stream.empty();

  Timer? _timer;
  DateTime? _startMoment;

  ShotClock() {
    stream = _streamController.stream.asBroadcastStream();
  }
  @override
  Future<void> start() async {
    _startMoment = DateTime.now();
    _streamController.add(TimerStarted(_startMoment!, 0));

    _timer = Timer.periodic(
      const Duration(milliseconds: 100),
      (Timer t) => _emitTickEvent(),
    );
  }

  void _emitTickEvent() {
    _streamController.add(
      TimerTicked(
        DateTime.now(),
        DateTime.now().difference(_startMoment!).inMilliseconds,
      ),
    );
  }

  @override
  Future<void> stop() async {
    _timer?.cancel();
    DateTime stopMoment = DateTime.now();
    _streamController.add(
      TimerStopped(
        stopMoment,
        DateTime.now().difference(_startMoment!).inMilliseconds,
      ),
    );
  }

  @override
  bool get isRunning => _timer?.isActive == true;
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `fvm flutter test test/domain/shot/shot_clock_test.dart -v`
Expected: PASS (3 tests)

- [ ] **Step 5: Delete the old file and commit**

```bash
rm lib/devices/timer/timer_service.dart
git add lib/domain/shot/shot_clock.dart lib/devices/timer/timer_service.dart test/domain/shot/shot_clock_test.dart
git commit -m "domain: move TimerService to domain as ShotClock, add coverage"
```

---

## Task 10: Move and rename `AutoTareService` → `AutoTareRule`

**Files:**
- Create: `lib/domain/shot/auto_tare_rule.dart`
- Delete: `lib/services/auto_tare_service.dart`
- Move+modify: `test/services/auto_tare_service_test.dart` → `test/domain/shot/auto_tare_rule_test.dart`
- Regenerate: `test/domain/shot/auto_tare_rule_test.mocks.dart` (via build_runner; delete stale `test/services/auto_tare_service_test.mocks.dart`)

**Interfaces:**
- Consumes: `ScaleRepository` (Task 4), `ScaleEvent`/`WeightReading` (Task 1).
- Produces: `abstract class AbstractAutoTareRule { void start(); void stop(); }`, `class AutoTareRule implements AbstractAutoTareRule`.

This class's logic is unchanged — only the type names it references change (`AbstractScaleService`→`ScaleRepository`, `WeightNotification`→`WeightReading`, `Notification`→`ScaleEvent`). The existing test suite already covers its behavior; it moves and gets its mock target updated.

- [ ] **Step 1: Write the (moved) test against the not-yet-existing new types**

```dart
// test/domain/shot/auto_tare_rule_test.dart
import 'package:espresso_log/domain/shot/auto_tare_rule.dart';
import 'package:espresso_log/domain/telemetry/scale_event.dart';
import 'package:espresso_log/domain/telemetry/scale_repository.dart';
import 'package:espresso_log/domain/telemetry/weight_reading.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:rxdart/rxdart.dart';

@GenerateNiceMocks([MockSpec<ScaleRepository>()])
import 'auto_tare_rule_test.mocks.dart';

void main() {
  test('stable weight increase should trigger tare', () async {
    var fakeScaleRepository = MockScaleRepository();
    var controller = BehaviorSubject<ScaleEvent>();
    when(fakeScaleRepository.stream).thenAnswer((_) => controller);

    var autoTareRule = AutoTareRule(fakeScaleRepository);
    var startTime = DateTime(2020, 02, 03, 10, 11);

    // when
    autoTareRule.start();
    controller.add(WeightReading(weight: 10, timeStamp: startTime));
    controller.add(
      WeightReading(
        weight: 62,
        timeStamp: startTime.add(const Duration(milliseconds: 1)),
      ),
    );

    controller.add(
      WeightReading(
        weight: 62,
        timeStamp: startTime.add(const Duration(milliseconds: 1002)),
      ),
    );

    // then
    await untilCalled(fakeScaleRepository.tareCommand());
    verify(fakeScaleRepository.tareCommand()).called(1);
  });

  test('unstable weight should not trigger tare', () async {
    var fakeScaleRepository = MockScaleRepository();
    var controller = BehaviorSubject<ScaleEvent>();
    when(fakeScaleRepository.stream).thenAnswer((_) => controller);

    var autoTareRule = AutoTareRule(fakeScaleRepository);
    var startTime = DateTime(2020, 02, 03, 10, 11);

    // when
    autoTareRule.start();
    controller.add(WeightReading(weight: 10, timeStamp: startTime));
    controller.add(
      WeightReading(
        weight: 62,
        timeStamp: startTime.add(const Duration(milliseconds: 1)),
      ),
    );

    controller.add(
      WeightReading(
        weight: 62.3,
        timeStamp: startTime.add(const Duration(milliseconds: 1002)),
      ),
    );

    // then
    await pumpEventQueue();
    verifyNever(fakeScaleRepository.tareCommand());
  });

  test('stable weight for short period should not trigger tare', () async {
    var fakeScaleRepository = MockScaleRepository();
    var controller = BehaviorSubject<ScaleEvent>();
    when(fakeScaleRepository.stream).thenAnswer((_) => controller);

    var autoTareRule = AutoTareRule(fakeScaleRepository);
    var startTime = DateTime(2020, 02, 03, 10, 11);

    // when
    autoTareRule.start();
    controller.add(WeightReading(weight: 10, timeStamp: startTime));
    controller.add(
      WeightReading(
        weight: 62,
        timeStamp: startTime.add(const Duration(milliseconds: 1)),
      ),
    );

    controller.add(
      WeightReading(
        weight: 62,
        timeStamp: startTime.add(const Duration(milliseconds: 101)),
      ),
    );

    // then
    await pumpEventQueue();
    verifyNever(fakeScaleRepository.tareCommand());
  });

  test('stable low weight increase should not trigger tare', () async {
    var fakeScaleRepository = MockScaleRepository();
    var controller = BehaviorSubject<ScaleEvent>();
    when(fakeScaleRepository.stream).thenAnswer((_) => controller);

    var autoTareRule = AutoTareRule(fakeScaleRepository);
    var startTime = DateTime(2020, 02, 03, 10, 11);

    // when
    autoTareRule.start();
    controller.add(WeightReading(weight: 10, timeStamp: startTime));
    controller.add(
      WeightReading(
        weight: 20,
        timeStamp: startTime.add(const Duration(milliseconds: 1)),
      ),
    );

    controller.add(
      WeightReading(
        weight: 20,
        timeStamp: startTime.add(const Duration(milliseconds: 2001)),
      ),
    );

    // then
    await pumpEventQueue();
    verifyNever(fakeScaleRepository.tareCommand());
  });
}
```

- [ ] **Step 2: Delete the old test and its stale generated mocks**

```bash
rm test/services/auto_tare_service_test.dart test/services/auto_tare_service_test.mocks.dart
```

Run: `fvm flutter test test/domain/shot/auto_tare_rule_test.dart -v`
Expected: FAIL — neither `lib/domain/shot/auto_tare_rule.dart` nor the generated `auto_tare_rule_test.mocks.dart` exist yet.

- [ ] **Step 3: Write the implementation**

```dart
// lib/domain/shot/auto_tare_rule.dart
import 'dart:async';

import 'package:espresso_log/domain/telemetry/scale_repository.dart';
import 'package:espresso_log/domain/telemetry/weight_reading.dart';

abstract class AbstractAutoTareRule {
  void start();
  void stop();
}

class AutoTareRule implements AbstractAutoTareRule {
  final ScaleRepository scaleRepository;
  StreamSubscription? scaleSubscription;
  List<WeightReading> _history = [];
  double? _startWeight;

  AutoTareRule(this.scaleRepository);

  @override
  void start() {
    scaleSubscription = scaleRepository.stream
        .where((event) => event is WeightReading)
        .cast<WeightReading>()
        .listen((weightReading) {
          if (_startWeight == null) {
            _startWeight = weightReading.weight;
            return;
          }

          if (weightReading.weight < _startWeight! + 50) {
            _history = [];
            return;
          }

          // first 'interesting' weight
          // just store
          if (_history.isEmpty) {
            _history.add(weightReading);
            return;
          }

          // weight not stable: reset
          if (weightReading.weight - 0.2 > _history.last.weight ||
              weightReading.weight + 0.2 < _history.last.weight) {
            _history = [];
            _history.add(weightReading);
            return;
          }

          // weight is stable
          _history.add(weightReading);
          if (weightReading.timeStamp
                  .difference(_history.first.timeStamp)
                  .inMilliseconds >
              1000) {
            scaleRepository.tareCommand();
            stop();
          }
        });
  }

  @override
  void stop() {
    scaleSubscription?.cancel();
    _startWeight = null;
    _history = [];
  }
}
```

- [ ] **Step 4: Regenerate mocks and run the test**

Run: `fvm dart run build_runner build --delete-conflicting-outputs`
Expected: generates `test/domain/shot/auto_tare_rule_test.mocks.dart` with a `MockScaleRepository` class.

Run: `fvm flutter test test/domain/shot/auto_tare_rule_test.dart -v`
Expected: PASS (4 tests)

- [ ] **Step 5: Delete the old implementation file and commit**

```bash
rm lib/services/auto_tare_service.dart
git add lib/domain/shot/auto_tare_rule.dart lib/services/auto_tare_service.dart test/domain/shot/auto_tare_rule_test.dart test/domain/shot/auto_tare_rule_test.mocks.dart test/services/auto_tare_service_test.dart test/services/auto_tare_service_test.mocks.dart
git commit -m "domain: move AutoTareService to domain as AutoTareRule, move tests"
```

---

## Task 11: Move and rename `AutoStartStopService` → `AutoStartStopRule`

**Files:**
- Create: `lib/domain/shot/auto_start_stop_rule.dart`
- Delete: `lib/services/auto_start_stop_service.dart`

**Interfaces:**
- Consumes: `PressureRepository` (Task 4), `PressureReading` (Task 2), `AbstractShotClock` (Task 5).
- Produces: `abstract class AbstractAutoStartStopRule { void enable(); void disable(); }`, `class AutoStartStopRule implements AbstractAutoStartStopRule`.

No existing test suite covers this class today, and this task doesn't add one (matching the "no behavior change" constraint without expanding scope) — it moves and retypes only. It becomes trivially testable with `MockPressureRepository`/`MockAbstractShotClock` later if desired, but that's not part of this plan.

- [ ] **Step 1: Write the implementation**

```dart
// lib/domain/shot/auto_start_stop_rule.dart
import 'dart:async';

import 'package:espresso_log/domain/shot/abstract_shot_clock.dart';
import 'package:espresso_log/domain/telemetry/pressure_reading.dart';
import 'package:espresso_log/domain/telemetry/pressure_repository.dart';

abstract class AbstractAutoStartStopRule {
  void enable();
  void disable();
}

class AutoStartStopRule implements AbstractAutoStartStopRule {
  bool _enabled = false;
  final double _treshold1 = 0.1;
  final double _treshold2 = 0.5;
  bool _treshold2Reached = false;
  StreamSubscription<PressureReading>? _pressureSubscription;

  AutoStartStopRule(
    PressureRepository pressureRepository,
    AbstractShotClock shotClock,
  ) {
    _pressureSubscription = pressureRepository.stream.listen((reading) {
      if (!_enabled) {
        return;
      }

      // start
      if (!shotClock.isRunning && reading.pressure > _treshold1) {
        shotClock.start();
        return;
      }

      // treshold2 reached
      if (shotClock.isRunning && reading.pressure >= _treshold2) {
        _treshold2Reached = true;
        return;
      }

      // below treshold2
      if (shotClock.isRunning &&
          _treshold2Reached &&
          reading.pressure < _treshold2) {
        _enabled = false;
        shotClock.stop();
      }
    });
  }

  @override
  void enable() {
    if (_pressureSubscription != null && _pressureSubscription!.isPaused) {
      _pressureSubscription!.resume();
    }
    _enabled = true;
  }

  @override
  void disable() {
    if (_pressureSubscription != null) {
      _pressureSubscription!.pause();
    }
    _treshold2Reached = false;
    _enabled = false;
  }
}
```

- [ ] **Step 2: Verify it compiles in isolation**

Run: `fvm flutter analyze lib/domain/shot/auto_start_stop_rule.dart`
Expected: No issues found.

- [ ] **Step 3: Delete the old file and commit**

```bash
rm lib/services/auto_start_stop_service.dart
git add lib/domain/shot/auto_start_stop_rule.dart lib/services/auto_start_stop_service.dart
git commit -m "domain: move AutoStartStopService to domain as AutoStartStopRule"
```

---

## Task 12: `ShotGraphPoint`, `ShotSnapshot`, and the new `ShotRecordingSession`

This is the main deliverable of the whole refactor: the accumulation and tare-zeroing math that today lives inline in `ShotGraphCubit._emitEvent` (untested) becomes a pure, synchronous, fully-tested domain class.

**Files:**
- Create: `lib/domain/shot/shot_graph_point.dart`
- Create: `lib/domain/shot/shot_snapshot.dart`
- Create: `lib/domain/shot/shot_recording_session.dart`
- Test: `test/domain/shot/shot_recording_session_test.dart`

**Interfaces:**
- Consumes: `WeightReading` (Task 1), `PressureReading` (Task 2).
- Produces: `class ShotGraphPoint { final int millisecond; final double value; }`; `class ShotSnapshot { final List<ShotGraphPoint> weightData; final List<ShotGraphPoint> pressureData; }`; `class ShotRecordingSession` with `start(DateTime)`, `stop()`, `reset()`, `tare(DateTime)`, `addWeight(WeightReading)`, `addPressure(PressureReading)`, `bool get isStarted`, `ShotSnapshot get snapshot`.

- [ ] **Step 1: Write the failing tests**

```dart
// test/domain/shot/shot_recording_session_test.dart
import 'package:espresso_log/domain/shot/shot_recording_session.dart';
import 'package:espresso_log/domain/telemetry/pressure_reading.dart';
import 'package:espresso_log/domain/telemetry/weight_reading.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final t0 = DateTime(2026, 1, 1, 8, 0, 0);

  test('snapshot before start returns empty series', () {
    final session = ShotRecordingSession();

    expect(session.isStarted, isFalse);
    expect(session.snapshot.weightData, isEmpty);
    expect(session.snapshot.pressureData, isEmpty);
  });

  test('weight is offset in milliseconds relative to the start time', () {
    final session = ShotRecordingSession()..start(t0);

    session.addWeight(
      WeightReading(weight: 18, timeStamp: t0.add(const Duration(milliseconds: 2500))),
    );

    expect(session.snapshot.weightData, [
      predicate<dynamic>((p) => p.millisecond == 2500 && p.value == 18),
    ]);
  });

  test('pressure is offset in milliseconds relative to the start time', () {
    final session = ShotRecordingSession()..start(t0);

    session.addPressure(
      PressureReading(6.5, t0.add(const Duration(milliseconds: 4000))),
    );

    expect(session.snapshot.pressureData, [
      predicate<dynamic>((p) => p.millisecond == 4000 && p.value == 6.5),
    ]);
  });

  test('weight readings before the tare timestamp are zeroed', () {
    final session = ShotRecordingSession()..start(t0);

    session.addWeight(
      WeightReading(weight: 5, timeStamp: t0.add(const Duration(milliseconds: 100))),
    );
    session.tare(t0.add(const Duration(milliseconds: 200)));
    session.addWeight(
      WeightReading(weight: 18, timeStamp: t0.add(const Duration(milliseconds: 300))),
    );

    final weightData = session.snapshot.weightData;
    expect(weightData[0].value, 0);
    expect(weightData[1].value, 18);
  });

  test('weight readings after the tare timestamp keep their real value', () {
    final session = ShotRecordingSession()..start(t0);

    session.tare(t0.add(const Duration(milliseconds: 100)));
    session.addWeight(
      WeightReading(weight: 24.3, timeStamp: t0.add(const Duration(milliseconds: 150))),
    );

    expect(session.snapshot.weightData.single.value, 24.3);
  });

  test('without a tare event no weight is zeroed', () {
    final session = ShotRecordingSession()..start(t0);

    session.addWeight(
      WeightReading(weight: 7, timeStamp: t0.add(const Duration(milliseconds: 50))),
    );

    expect(session.snapshot.weightData.single.value, 7);
  });

  test('reset clears accumulated data and the tare timestamp', () {
    final session = ShotRecordingSession()..start(t0);
    session.addWeight(WeightReading(weight: 5, timeStamp: t0));
    session.tare(t0);

    session.reset();

    expect(session.isStarted, isFalse);
    expect(session.snapshot.weightData, isEmpty);

    // starting again and adding a weight after the old tare timestamp
    // must not be zeroed, proving the tare timestamp itself was cleared
    session.start(t0.add(const Duration(seconds: 10)));
    session.addWeight(
      WeightReading(weight: 30, timeStamp: t0.add(const Duration(seconds: 11))),
    );
    expect(session.snapshot.weightData.single.value, 30);
  });

  test('stop keeps the accumulated data but marks the session as not started', () {
    final session = ShotRecordingSession()..start(t0);
    session.addWeight(
      WeightReading(weight: 12, timeStamp: t0.add(const Duration(milliseconds: 500))),
    );

    session.stop();

    expect(session.isStarted, isFalse);
    // data from before stop() is still readable — mirrors today's
    // ShotGraphCubit, which emits the ShotGraphStopped snapshot using the
    // still-populated lists before nulling _startDateTime.
    expect(session.snapshot.weightData, isEmpty);
  });
}
```

Note on the last test: once `isStarted` is false, `snapshot` returns empty series by definition (there's no `_startDateTime` left to compute millisecond offsets against) — this documents that callers must read `snapshot` *before* calling `stop()` if they need the final data, exactly like `ShotGraphCubit` will in Task 13.

- [ ] **Step 2: Run tests to verify they fail**

Run: `fvm flutter test test/domain/shot/shot_recording_session_test.dart -v`
Expected: FAIL — `lib/domain/shot/shot_recording_session.dart` and its dependencies don't exist yet.

- [ ] **Step 3: Write the implementation**

```dart
// lib/domain/shot/shot_graph_point.dart
class ShotGraphPoint {
  final int millisecond;
  final double value;

  ShotGraphPoint(this.millisecond, this.value);
}
```

```dart
// lib/domain/shot/shot_snapshot.dart
import 'package:espresso_log/domain/shot/shot_graph_point.dart';

class ShotSnapshot {
  final List<ShotGraphPoint> weightData;
  final List<ShotGraphPoint> pressureData;

  const ShotSnapshot({required this.weightData, required this.pressureData});

  static const empty = ShotSnapshot(weightData: [], pressureData: []);
}
```

```dart
// lib/domain/shot/shot_recording_session.dart
import 'package:espresso_log/domain/shot/shot_graph_point.dart';
import 'package:espresso_log/domain/shot/shot_snapshot.dart';
import 'package:espresso_log/domain/telemetry/pressure_reading.dart';
import 'package:espresso_log/domain/telemetry/weight_reading.dart';

class ShotRecordingSession {
  DateTime? _startDateTime;
  DateTime? _tareDateTime;
  final List<WeightReading> _weightReadings = [];
  final List<PressureReading> _pressureReadings = [];

  bool get isStarted => _startDateTime != null;

  void start(DateTime startDateTime) {
    _startDateTime = startDateTime;
    _tareDateTime = null;
    _weightReadings.clear();
    _pressureReadings.clear();
  }

  /// Marks the session as no longer running, keeping accumulated readings
  /// intact so a final [snapshot] can still be read afterwards. Mirrors
  /// legacy ShotGraphCubit, which nulled _startDateTime on stop without
  /// clearing its notification lists.
  void stop() {
    _startDateTime = null;
  }

  void reset() {
    _startDateTime = null;
    _tareDateTime = null;
    _weightReadings.clear();
    _pressureReadings.clear();
  }

  void tare(DateTime tareDateTime) {
    _tareDateTime = tareDateTime;
  }

  void addWeight(WeightReading reading) {
    _weightReadings.add(reading);
  }

  void addPressure(PressureReading reading) {
    _pressureReadings.add(reading);
  }

  ShotSnapshot get snapshot {
    final startDateTime = _startDateTime;
    if (startDateTime == null) {
      return ShotSnapshot.empty;
    }

    final pressureData = _pressureReadings.map((reading) {
      return ShotGraphPoint(
        reading.timeStamp.difference(startDateTime).inMilliseconds,
        reading.pressure,
      );
    }).toList();

    final tareDateTime = _tareDateTime;
    final weightData = _weightReadings.map((reading) {
      if (tareDateTime == null || reading.timeStamp.isAfter(tareDateTime)) {
        return ShotGraphPoint(
          reading.timeStamp.difference(startDateTime).inMilliseconds,
          reading.weight,
        );
      }
      return ShotGraphPoint(
        reading.timeStamp.difference(startDateTime).inMilliseconds,
        0,
      );
    }).toList();

    return ShotSnapshot(weightData: weightData, pressureData: pressureData);
  }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `fvm flutter test test/domain/shot/shot_recording_session_test.dart -v`
Expected: PASS (8 tests)

- [ ] **Step 5: Commit**

```bash
git add lib/domain/shot/shot_graph_point.dart lib/domain/shot/shot_snapshot.dart lib/domain/shot/shot_recording_session.dart test/domain/shot/shot_recording_session_test.dart
git commit -m "domain: add ShotRecordingSession with ShotGraphPoint/ShotSnapshot, extracted from ShotGraphCubit"
```

---

## Task 13: Rewire `ShotGraphCubit`, `ShotGraphState`, `ShotGraphWidget`

**Files:**
- Modify: `lib/ui/shot/shot_graph/shot_graph_cubit.dart`
- Modify: `lib/ui/shot/shot_graph/shot_graph_state.dart`
- Modify: `lib/ui/shot/shot_graph/shot_graph_widget.dart`

**Interfaces:**
- Consumes: `ScaleRepository`/`ScaleEvent`/`WeightReading`/`TareEvent` (Tasks 1, 4), `PressureRepository`/`PressureReading` (Tasks 2, 4), `AbstractShotClock`/`TimerEvent`/`TimerStarted`/`TimerStopped` (Tasks 3, 5), `AbstractAutoTareRule` (Task 10), `AbstractAutoStartStopRule` (Task 11), `ShotRecordingSession`/`ShotGraphPoint` (Task 12).
- Produces: `ShotGraphCubit` with the same public API as before (`start()`, `restart()`, `close()`) and the same constructor parameter order, so `main.dart` (Task 17) only needs an import/type update, not a call-site change.

No new tests here — `ShotGraphCubit` has no existing test suite, and this task is a pure rewire onto already-tested (`ShotRecordingSession`, `AutoTareRule`) or already-covered-by-manual-smoke-test (`ShotClock`) building blocks. Regression coverage comes from Task 18's `flutter run --dart-define USE_MOCK_SCALE=true --dart-define USE_MOCK_PRESSURE=true` manual pass.

- [ ] **Step 1: Rewrite `shot_graph_cubit.dart`**

```dart
// lib/ui/shot/shot_graph/shot_graph_cubit.dart
import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:espresso_log/domain/shot/abstract_shot_clock.dart';
import 'package:espresso_log/domain/shot/auto_start_stop_rule.dart';
import 'package:espresso_log/domain/shot/auto_tare_rule.dart';
import 'package:espresso_log/domain/shot/shot_graph_point.dart';
import 'package:espresso_log/domain/shot/shot_recording_session.dart';
import 'package:espresso_log/domain/shot/timer_event.dart';
import 'package:espresso_log/domain/telemetry/pressure_reading.dart';
import 'package:espresso_log/domain/telemetry/pressure_repository.dart';
import 'package:espresso_log/domain/telemetry/scale_event.dart';
import 'package:espresso_log/domain/telemetry/scale_repository.dart';
import 'package:espresso_log/domain/telemetry/tare_event.dart';
import 'package:espresso_log/domain/telemetry/weight_reading.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'shot_graph_state.dart';

class ShotGraphCubit extends Cubit<ShotGraphState> {
  final AbstractAutoStartStopRule _autoStartStopRule;
  final ScaleRepository _scaleRepository;
  final AbstractShotClock _shotClock;
  final AbstractAutoTareRule _autoTareRule;
  final PressureRepository _pressureRepository;
  final ShotRecordingSession _session = ShotRecordingSession();
  bool _isRunning = false;
  StreamSubscription<TimerEvent>? _timerStreamSubscription;
  StreamSubscription<ScaleEvent>? _scaleStreamSubscription;
  StreamSubscription<PressureReading>? _pressureStreamSubscription;

  ShotGraphCubit(
    this._autoStartStopRule,
    this._scaleRepository,
    this._shotClock,
    this._autoTareRule,
    this._pressureRepository,
  ) : super(ShotGraphInitial());

  void _handleTimerUpdates() {
    _timerStreamSubscription = _shotClock.stream.listen((timerEvent) {
      if (timerEvent is TimerStarted) {
        _isRunning = true;
        _session.start(timerEvent.timeStamp);
      } else if (timerEvent is TimerStopped) {
        _isRunning = false;
        _autoTareRule.stop();
        final snapshot = _session.snapshot;
        emit(ShotGraphStopped(snapshot.pressureData, snapshot.weightData));
        _session.stop();
      }
    });
  }

  void _handleScaleUpdates() {
    _scaleStreamSubscription = _scaleRepository.stream.listen((scaleEvent) {
      if (!_session.isStarted || !_isRunning) return;
      if (scaleEvent is TareEvent) {
        _session.tare(scaleEvent.timeStamp);
      } else if (scaleEvent is WeightReading) {
        _session.addWeight(scaleEvent);
      }
      final snapshot = _session.snapshot;
      emit(ShotGraphUpdating(snapshot.pressureData, snapshot.weightData));
    });
  }

  void _handlePressureUpdates() {
    _pressureStreamSubscription = _pressureRepository.stream.listen((
      pressureReading,
    ) {
      if (!_session.isStarted || !_isRunning) return;
      _session.addPressure(pressureReading);
      final snapshot = _session.snapshot;
      emit(ShotGraphUpdating(snapshot.pressureData, snapshot.weightData));
    });
  }

  void start() {
    emit(ShotGraphWaiting());
    _isRunning = false;
    _session.reset();

    _handleTimerUpdates();
    _handleScaleUpdates();
    _handlePressureUpdates();
    _autoTareRule.start();
    _autoStartStopRule.enable();
  }

  void restart() {
    emit(ShotGraphWaiting());
    _isRunning = false;
    _session.reset();
    _autoTareRule.start();
    _autoStartStopRule.enable();
  }

  @override
  Future<void> close() {
    _autoStartStopRule.disable();
    _autoTareRule.stop();
    _timerStreamSubscription?.cancel();
    _scaleStreamSubscription?.cancel();
    _pressureStreamSubscription?.cancel();

    return super.close();
  }
}
```

- [ ] **Step 2: Rewrite `shot_graph_state.dart`**

```dart
// lib/ui/shot/shot_graph/shot_graph_state.dart
part of 'shot_graph_cubit.dart';

sealed class ShotGraphState {}

final class ShotGraphInitial extends ShotGraphState {}

final class ShotGraphWaiting extends ShotGraphState {}

final class ShotGraphRun extends ShotGraphState with EquatableMixin {
  final List<ShotGraphPoint> pressureData;
  final List<ShotGraphPoint> weightData;
  ShotGraphRun(this.pressureData, this.weightData);

  @override
  List<Object?> get props => [pressureData, weightData];
}

final class ShotGraphUpdating extends ShotGraphRun {
  ShotGraphUpdating(super.pressureData, super.weightData);
}

final class ShotGraphStopped extends ShotGraphRun {
  ShotGraphStopped(super.pressureData, super.weightData);
}
```

(Note: this also fixes a pre-existing typo — the old file had `super.weightDat` on the `ShotGraphUpdating` constructor line, which happened to still work because `super.weightDat` was itself the parameter name shorthand; it's now spelled correctly as `weightData` for clarity. No behavioral difference.)

- [ ] **Step 3: Update `shot_graph_widget.dart` to use `ShotGraphPoint`**

Replace both occurrences of `ShotGraphData` in `lib/ui/shot/shot_graph/shot_graph_widget.dart` with `ShotGraphPoint`, and both `(ShotGraphData sgd, _)` lambda parameter types accordingly. Add the import:

```dart
import 'package:espresso_log/domain/shot/shot_graph_point.dart';
```

The full resulting file:

```dart
// lib/ui/shot/shot_graph/shot_graph_widget.dart
import 'package:espresso_log/domain/shot/shot_graph_point.dart';
import 'package:espresso_log/ui/shot/shot_graph/shot_graph_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class ShotGraphWidget extends StatelessWidget {
  const ShotGraphWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // Call start() after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ShotGraphCubit>().start();
    });

    return BlocBuilder<ShotGraphCubit, ShotGraphState>(
      builder: (context, state) {
        if (state is ShotGraphInitial || state is ShotGraphWaiting) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text("Waiting for shot to start..."),
              ],
            ),
          );
        }

        if (state is ShotGraphRun) {
          return _getShotGraph(state);
        }

        return const Text('Error! Unexpected state');
      },
    );
  }

  Widget _getShotGraph(ShotGraphRun shotGraphRun) {
    var maxWeight = shotGraphRun.weightData.fold(
      0.0,
      (value, element) => value > element.value ? value : element.value,
    );
    if (maxWeight < 40) {
      maxWeight = 40;
    }

    var maxPressure = shotGraphRun.pressureData.fold(
      0.0,
      (value, element) => value > element.value ? value : element.value,
    );
    if (maxPressure < 10) {
      maxPressure = 10;
    }

    var maxMillisPressure = shotGraphRun.pressureData.fold(
      0,
      (value, element) =>
          value > element.millisecond ? value : element.millisecond,
    );

    var maxMillisGrams = shotGraphRun.weightData.fold(
      0,
      (value, element) =>
          value > element.millisecond ? value : element.millisecond,
    );

    var maxMillis = maxMillisPressure > maxMillisGrams
        ? maxMillisPressure
        : maxMillisGrams;

    double maxSeconds = 40;
    if (maxMillis > 40000) {
      maxSeconds = ((maxMillis / 10000).ceil()) * 10;
    }

    return Card(
      clipBehavior: Clip.hardEdge,
      child: SfCartesianChart(
        legend: const Legend(isVisible: true),
        primaryXAxis: NumericAxis(
          title: const AxisTitle(text: 'Seconds'),
          minimum: 0,
          maximum: maxSeconds,
        ),
        primaryYAxis: NumericAxis(
          name: 'Grams',
          minimum: 0,
          maximum: maxWeight,
        ),
        axes: <ChartAxis>[
          NumericAxis(
            name: 'bar',
            opposedPosition: true,
            interval: 1,
            minimum: 0,
            maximum: maxPressure,
          ),
        ],
        series: <CartesianSeries>[
          SplineSeries<ShotGraphPoint, double>(
            name: 'Grams',
            dataSource: shotGraphRun.weightData,
            animationDuration: 0,
            splineType: SplineType.natural,
            isVisibleInLegend: true,
            emptyPointSettings: const EmptyPointSettings(
              mode: EmptyPointMode.average,
            ),
            xValueMapper: (ShotGraphPoint sgd, _) =>
                (sgd.millisecond / 1000).roundToDouble(),
            yValueMapper: (ShotGraphPoint sgd, _) => sgd.value,
          ),
          SplineSeries<ShotGraphPoint, double>(
            name: 'Bar',
            dataSource: shotGraphRun.pressureData,
            animationDuration: 0,
            isVisibleInLegend: true,
            splineType: SplineType.natural,
            emptyPointSettings: const EmptyPointSettings(
              mode: EmptyPointMode.average,
            ),
            xValueMapper: (ShotGraphPoint sgd, _) =>
                (sgd.millisecond / 1000).roundToDouble(),
            yValueMapper: (ShotGraphPoint sgd, _) => sgd.value,
            yAxisName: 'bar',
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Verify these three files compile together**

Run: `fvm flutter analyze lib/ui/shot/shot_graph/shot_graph_cubit.dart lib/ui/shot/shot_graph/shot_graph_state.dart lib/ui/shot/shot_graph/shot_graph_widget.dart`
Expected: No issues found. (Whole-project analyze still fails until Task 17 — `main.dart` still constructs `ShotGraphCubit` with the old device types.)

- [ ] **Step 5: Commit**

```bash
git add lib/ui/shot/shot_graph/shot_graph_cubit.dart lib/ui/shot/shot_graph/shot_graph_state.dart lib/ui/shot/shot_graph/shot_graph_widget.dart
git commit -m "ui: rewire ShotGraphCubit onto ShotRecordingSession and domain types"
```

---

## Task 14: Rewire `CurrentWeightCubit`, `WeightChangeCubit`

**Files:**
- Modify: `lib/ui/components/current-weight/current_weight_cubit.dart`
- Modify: `lib/ui/components/weight-change/weight_change_cubit.dart`

**Interfaces:**
- Consumes: `ScaleRepository` (Task 4), `WeightReading`/`TareEvent` (Task 1).

- [ ] **Step 1: Rewrite `current_weight_cubit.dart`**

```dart
// lib/ui/components/current-weight/current_weight_cubit.dart
import 'package:equatable/equatable.dart';
import 'package:espresso_log/domain/telemetry/scale_repository.dart';
import 'package:espresso_log/domain/telemetry/weight_reading.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'current_weight_state.dart';

class CurrentWeightCubit extends Cubit<CurrentWeightState> {
  final ScaleRepository _scaleRepository;

  CurrentWeightCubit(this._scaleRepository) : super(CurrentWeightInitial()) {
    _scaleRepository.stream.listen((event) {
      if (event is WeightReading) {
        emit(CurrentWeightMeasured(event.weight));
      }
    });
  }
}
```

- [ ] **Step 2: Rewrite `weight_change_cubit.dart`**

```dart
// lib/ui/components/weight-change/weight_change_cubit.dart
import 'package:equatable/equatable.dart';
import 'package:espresso_log/domain/telemetry/scale_repository.dart';
import 'package:espresso_log/domain/telemetry/tare_event.dart';
import 'package:espresso_log/domain/telemetry/weight_reading.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'weight_change_state.dart';

class WeightChangeCubit extends Cubit<WeightChangeState> {
  final ScaleRepository _scaleRepository;
  final List<WeightReading> _history = [];
  WeightChangeCubit(this._scaleRepository) : super(WeightChangeInitial()) {
    _scaleRepository.stream.listen((event) {
      // remove event occured before taring
      if (event is TareEvent) {
        _history.removeWhere(
          (element) => element.timeStamp.isBefore(event.timeStamp),
        );
        return;
      }

      if (event is WeightReading == false) return;

      // cleanup history
      var removeBefore = event.timeStamp.subtract(
        const Duration(milliseconds: 600),
      );
      _history.removeWhere(
        (element) => element.timeStamp.isBefore(removeBefore),
      );

      // add to history
      _history.add(event as WeightReading);

      // emit average
      if (_history.length > 1) {
        var first = _history.first;
        var last = _history.last;
        var weightDiff = last.weight - first.weight;
        var duration = last.timeStamp
            .difference(first.timeStamp)
            .inMilliseconds;
        var weightChange = weightDiff / duration * 1000;
        emit(WeightChangeUpdated(weightChange));
      }
    });
  }
}
```

- [ ] **Step 3: Verify these compile together**

Run: `fvm flutter analyze lib/ui/components/current-weight/current_weight_cubit.dart lib/ui/components/weight-change/weight_change_cubit.dart`
Expected: No issues found.

- [ ] **Step 4: Commit**

```bash
git add lib/ui/components/current-weight/current_weight_cubit.dart lib/ui/components/weight-change/weight_change_cubit.dart
git commit -m "ui: rewire CurrentWeightCubit and WeightChangeCubit onto ScaleRepository"
```

---

## Task 15: Rewire `PressureCubit`, `TimerCubit`

**Files:**
- Modify: `lib/ui/components/pressure/pressure_cubit.dart`
- Modify: `lib/ui/shot/timer/timer_cubit.dart`

**Interfaces:**
- Consumes: `PressureRepository` (Task 4), `AbstractShotClock`/`TimerEvent`/`TimerStarted`/`TimerTicked`/`TimerStopped` (Tasks 3, 5).

- [ ] **Step 1: Rewrite `pressure_cubit.dart`**

```dart
// lib/ui/components/pressure/pressure_cubit.dart
import 'package:equatable/equatable.dart';
import 'package:espresso_log/domain/telemetry/pressure_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'pressure_state.dart';

class PressureCubit extends Cubit<PressureState> {
  final PressureRepository _pressureRepository;

  PressureCubit(this._pressureRepository) : super(PressureInitial()) {
    _pressureRepository.stream.listen((event) {
      emit(Pressure(event.pressure));
    });
  }
}
```

- [ ] **Step 2: Rewrite `timer_cubit.dart`**

```dart
// lib/ui/shot/timer/timer_cubit.dart
import 'package:equatable/equatable.dart';
import 'package:espresso_log/domain/shot/abstract_shot_clock.dart';
import 'package:espresso_log/domain/shot/timer_event.dart' as timer_events;
import 'package:flutter_bloc/flutter_bloc.dart';

part 'timer_state.dart';

class TimerCubit extends Cubit<TimerState> {
  final AbstractShotClock _shotClock;

  TimerCubit(this._shotClock) : super(TimerInitial()) {
    _shotClock.stream.listen((event) {
      var seconds = (event.milliSeconds / 1000).floor();
      var deciSeconds = ((event.milliSeconds - 1000 * seconds) / 100).floor();
      if (event is timer_events.TimerStarted || event is timer_events.TimerTicked) {
        emit(TimerRunning(seconds, deciSeconds));
      }

      if (event is timer_events.TimerStopped) {
        emit(TimerStopped(seconds, deciSeconds));
      }
    });
  }
}
```

Note: `TimerStopped` is the name of both a domain `TimerEvent` subtype (Task 3) and this file's own `TimerState` subtype (declared in `timer_state.dart`, a `part of` this library, unchanged by this task). Declaring both in the same library is a hard compile error in Dart — it is **not** resolved "by context" — so the domain import above **must** use the `as timer_events` prefix; do not import it unprefixed.

- [ ] **Step 3: Verify these compile together**

Run: `fvm flutter analyze lib/ui/components/pressure/pressure_cubit.dart lib/ui/shot/timer/timer_cubit.dart`
Expected: No issues found.

- [ ] **Step 4: Commit**

```bash
git add lib/ui/components/pressure/pressure_cubit.dart lib/ui/shot/timer/timer_cubit.dart
git commit -m "ui: rewire PressureCubit and TimerCubit onto domain repositories"
```

---

## Task 16: Rewire `ConnectionCubit`, `SettingsScreen`, `RecorderScreen`

**Files:**
- Modify: `lib/ui/home/device_connection/connection_cubit.dart`
- Modify: `lib/ui/settings/settings.dart`
- Modify: `lib/ui/settings/recorder.dart`

**Interfaces:**
- Consumes: `ScaleRepository`/`PressureRepository` (Task 4), `AbstractShotClock` (Task 5), `BatteryDeviceMixin` (already at its new path from Task 6).

- [ ] **Step 1: Update `connection_cubit.dart`**

Replace the two service-type imports and the two constructor parameter/field types. Full resulting file:

```dart
// lib/ui/home/device_connection/connection_cubit.dart
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
```

- [ ] **Step 2: Update `settings.dart`**

Replace the import and the two `context.read<AbstractScaleService>()` call sites' type:

```dart
// lib/ui/settings/settings.dart
import 'package:espresso_log/domain/telemetry/scale_repository.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      // Center is a layout widget. It takes a single child and positions it
      // in the middle of the parent.
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          FilledButton(
            onPressed: () => context.push('/settings/log'),
            child: const Text("Logs"),
          ),
          FilledButton(
            onPressed: () => context.push('/settings/recorder'),
            child: const Text("Recorder"),
          ),
          FilledButton(
            onPressed: () => context.read<ScaleRepository>().init(),
            child: const Text("init"),
          ),
          FilledButton(
            onPressed: () => context.read<ScaleRepository>().tareCommand(),
            child: const Text("tare"),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 3: Update `recorder.dart`**

Replace the three service imports/types, and drop the now-unneeded `hide Notification` (the app no longer defines a `Notification` class, so it no longer collides with Flutter's own):

```dart
// lib/ui/settings/recorder.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:espresso_log/domain/shot/abstract_shot_clock.dart';
import 'package:espresso_log/domain/telemetry/pressure_repository.dart';
import 'package:espresso_log/domain/telemetry/scale_repository.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

class RecorderScreen extends StatefulWidget {
  const RecorderScreen({super.key});

  @override
  State<RecorderScreen> createState() => _RecorderScreenState();
}

class _RecorderScreenState extends State<RecorderScreen> {
  late final ScaleRepository _scaleRepository = context.read<ScaleRepository>();
  late final AbstractShotClock _shotClock = context.read<AbstractShotClock>();
  late final PressureRepository _pressureRepository = context
      .read<PressureRepository>();

  StreamSubscription? scaleSubscription;
  StreamSubscription? timerSubscription;
  StreamSubscription? pressureSubscription;

  List<Map<String, dynamic>> _events = [];

  @override
  void dispose() {
    _stopListening();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          FilledButton(
            onPressed: () => _listen(),
            child: const Text("Start recording"),
          ),
          FilledButton(
            onPressed: () => _stopListening(),
            child: const Text("Stop recording"),
          ),
          FilledButton(
            onPressed: () => _clear(),
            child: const Text("Flush recordings"),
          ),
          FilledButton(
            onPressed: () => _export(),
            child: const Text("Export recordings"),
          ),
        ],
      ),
    );
  }

  void _listen() {
    scaleSubscription = _scaleRepository.stream.listen((event) {
      setState(() {
        _events.add(event.toJson());
      });
    });
    timerSubscription = _shotClock.stream.listen((event) {
      setState(() {
        _events.add(event.toJson());
      });
    });
    pressureSubscription = _pressureRepository.stream.listen((event) {
      setState(() {
        _events.add(event.toJson());
      });
    });
  }

  void _stopListening() {
    scaleSubscription?.cancel();
    timerSubscription?.cancel();
    pressureSubscription?.cancel();
  }

  void _clear() {
    setState(() {
      _events = [];
    });
  }

  void _export() async {
    // Add this to your _export() method:
    final jsonlContent = _events.map((event) => jsonEncode(event)).join('\n');

    final directory = await getTemporaryDirectory();
    final file = File(
      '${directory.path}/espresso_recordings_${DateTime.now().millisecondsSinceEpoch}.jsonl',
    );

    await file.writeAsString(jsonlContent);

    await SharePlus.instance.share(
      ShareParams(
        text: "Espresso recordings",
        files: [XFile(file.path)],
        subject: "Espresso Log Recordings",
      ),
    );
  }
}
```

- [ ] **Step 4: Verify these compile together**

Run: `fvm flutter analyze lib/ui/home/device_connection/connection_cubit.dart lib/ui/settings/settings.dart lib/ui/settings/recorder.dart`
Expected: No issues found.

- [ ] **Step 5: Commit**

```bash
git add lib/ui/home/device_connection/connection_cubit.dart lib/ui/settings/settings.dart lib/ui/settings/recorder.dart
git commit -m "ui: rewire ConnectionCubit, SettingsScreen, RecorderScreen onto domain repositories"
```

---

## Task 17: Rewire `main.dart`

**Files:**
- Modify: `lib/main.dart`

**Interfaces:**
- Consumes: every domain/data type produced by Tasks 1–16.

- [ ] **Step 1: Rewrite `main.dart`**

```dart
// lib/main.dart
import 'dart:async';

import 'package:espresso_log/data/pressure/bookoo_pressure_service.dart';
import 'package:espresso_log/data/pressure/mock_pressure_service.dart';
import 'package:espresso_log/data/scale/decent_scale_service.dart';
import 'package:espresso_log/data/scale/mock_scale_service.dart';
import 'package:espresso_log/domain/shot/abstract_shot_clock.dart';
import 'package:espresso_log/domain/shot/auto_start_stop_rule.dart';
import 'package:espresso_log/domain/shot/auto_tare_rule.dart';
import 'package:espresso_log/domain/shot/shot_clock.dart';
import 'package:espresso_log/domain/telemetry/pressure_repository.dart';
import 'package:espresso_log/domain/telemetry/scale_repository.dart';

import 'package:espresso_log/router.dart';

import 'package:espresso_log/ui/components/current-weight/current_weight_cubit.dart';
import 'package:espresso_log/ui/components/pressure/pressure_cubit.dart';
import 'package:espresso_log/ui/home/device_connection/connection_cubit.dart';
import 'package:espresso_log/ui/home/device_connection/connection_modal_wrapper.dart';
import 'package:espresso_log/ui/shot/shot_graph/shot_graph_cubit.dart';
import 'package:espresso_log/ui/shot/timer/timer_cubit.dart';
import 'package:espresso_log/ui/components/weight-change/weight_change_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:idle_detector_wrapper/idle_detector_wrapper.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:talker_flutter/talker_flutter.dart';

import 'data/bluetooth/bluetooth_devices_service.dart';

const useMockScale = bool.fromEnvironment(
  'USE_MOCK_SCALE',
  defaultValue: false,
);
const useMockPressure = bool.fromEnvironment(
  'USE_MOCK_PRESSURE',
  defaultValue: false,
);

final GlobalKey<NavigatorState> globalNavigatorKey =
    GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  WakelockPlus.enable();

  final Talker talker = TalkerFlutter.init();
  final BluetoothDevicesService bluetoothService = BluetoothDevicesService(
    talker: talker,
  );
  await bluetoothService.init();

  final AbstractShotClock shotClock = ShotClock();

  final scaleRepository = useMockScale
      ? MockScaleService()
      : DecentScaleService(bluetoothService, talker);

  final PressureRepository pressureRepository = useMockPressure
      ? MockPressureService()
      : BookooPressureService(bluetoothService, talker);

  final AbstractAutoTareRule autoTareRule = AutoTareRule(scaleRepository);
  final AbstractAutoStartStopRule autoStartStopRule = AutoStartStopRule(
    pressureRepository,
    shotClock,
  );
  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => ShotGraphCubit(
            autoStartStopRule,
            scaleRepository,
            shotClock,
            autoTareRule,
            pressureRepository,
          ),
        ),
        BlocProvider(create: (_) => CurrentWeightCubit(scaleRepository)),
        BlocProvider(create: (_) => WeightChangeCubit(scaleRepository)),
        BlocProvider(create: (_) => TimerCubit(shotClock)),
        BlocProvider(create: (_) => PressureCubit(pressureRepository)),
        BlocProvider(
          create: (_) =>
              ConnectionCubit(scaleRepository, pressureRepository)..connect(),
        ),
      ],
      child: MultiProvider(
        providers: [
          Provider<Talker>.value(value: talker),
          Provider<ScaleRepository>.value(value: scaleRepository),
          Provider<PressureRepository>.value(value: pressureRepository),
          Provider<AbstractShotClock>.value(value: shotClock),
        ],
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return IdleDetector(
      idleTime: const Duration(minutes: 5),
      onIdle: () {
        unawaited(context.read<ConnectionCubit>().disconnect());
      },
      onActive: () {
        unawaited(context.read<ConnectionCubit>().reconnect());
      },
      child: ConnectionModalWrapper(
        navigatorKey: globalNavigatorKey,
        child: MaterialApp.router(
          theme:
              ThemeData.from(
                colorScheme: ColorScheme.fromSeed(
                  seedColor: const Color.fromARGB(255, 84, 48, 134),
                ),
              ).copyWith(
                appBarTheme: const AppBarTheme(
                  backgroundColor: Color.fromARGB(255, 88, 77, 105),
                  foregroundColor: Colors.white,
                ),
              ),
          routerConfig: AppRouter(
            context.read<Talker>(),
            globalNavigatorKey,
          ).router,
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Verify the whole project analyzes clean**

Run: `fvm flutter analyze`
Expected: No issues found. Every consumer of the old `lib/devices`/`lib/services` types has now been rewired (Tasks 6–16); `lib/devices/` and `lib/services/` should at this point contain only their two remaining now-orphaned model folders (`lib/devices/scale/models/`, `lib/devices/pressure/models/`, `lib/devices/timer/models/`, `lib/devices/models/`), which are unreferenced dead code cleaned up in Task 18.

- [ ] **Step 3: Commit**

```bash
git add lib/main.dart
git commit -m "app: wire main.dart onto the new domain/data layers"
```

---

## Task 18: Delete the old `lib/devices`/`lib/services` trees and verify

**Files:**
- Delete: `lib/devices/` (entire remaining tree)
- Delete: `lib/services/` (entire remaining tree, if not already empty from Tasks 10–11)
- Modify: `CLAUDE.md` (architecture section)

- [ ] **Step 1: Confirm nothing still imports the old paths**

Run: `grep -rn "package:espresso_log/devices\|package:espresso_log/services" lib test`
Expected: no output. If anything is found, stop and fix that reference before deleting (it means an earlier task's rewire was missed).

- [ ] **Step 2: Delete the old trees**

```bash
rm -rf lib/devices lib/services
```

- [ ] **Step 3: Run full analyze and full test suite**

Run: `fvm flutter analyze`
Expected: No issues found.

Run: `fvm flutter test`
Expected: All tests pass (the full suite now includes `test/domain/telemetry/scale_event_test.dart`, `test/domain/telemetry/pressure_reading_test.dart`, `test/domain/shot/timer_event_test.dart`, `test/domain/shot/shot_clock_test.dart`, `test/domain/shot/auto_tare_rule_test.dart`, `test/domain/shot/shot_recording_session_test.dart`).

- [ ] **Step 4: Manual smoke test against mock devices**

Run: `fvm flutter run --dart-define USE_MOCK_SCALE=true --dart-define USE_MOCK_PRESSURE=true`
Expected: app launches, weight/pressure/timer widgets update from the mock streams, starting a shot from the home screen shows the live graph, and it auto-stops per the mock pressure profile — same behavior as before this refactor. This is the step that actually exercises `DecentScaleService`/`BookooPressureService`-shaped wiring end-to-end (via their mock siblings) since those two classes have no automated test coverage.

- [ ] **Step 5: Update `CLAUDE.md`'s architecture section**

Update the "Device layer", "Domain services orchestrate device streams into behavior", and "UI layer" subsections of `CLAUDE.md` to describe the new `lib/domain/` / `lib/data/` split instead of the old `lib/devices/` / `lib/services/` layout, and add a short mention of `ShotRecordingSession` replacing the inline math that section previously described as living in `ShotGraphCubit._emitEvent`.

- [ ] **Step 6: Commit**

```bash
git add -A
git commit -m "cleanup: remove old lib/devices and lib/services trees, update CLAUDE.md"
```

---

## Self-Review Notes

- **Spec coverage:** every bounded context in the spec (Telemetry, Shot timing incl. ShotClock reclassification, Auto-tare, Auto-start/stop, Shot recording, naming conventions, the `batter_device_mixin.dart` typo fix, the `hide Notification` removal) has a task. `DeviceConnectionSession` and `ShotRepository` are explicitly out of scope per the spec and are not tasked here.
- **Ordering:** value objects (1–3) → interfaces (4–5) → adapters that implement them (6–9) → rules that depend on them (10–11) → the new session (12) → every consumer rewired leaf-to-root (13–17) → deletion + verification (18). Each task's own new/moved files compile in isolation even when the whole-project `flutter analyze` is still mid-migration (noted explicitly in Tasks 7, 8, 13 where that applies).
- **Type consistency check:** `ScaleRepository.stream` is `Stream<ScaleEvent>` everywhere it's declared (Task 4) and consumed (Tasks 7, 10, 13, 14, 16); `ShotRecordingSession`'s method names (`start`, `stop`, `reset`, `tare`, `addWeight`, `addPressure`, `isStarted`, `snapshot`) as defined in Task 12 match exactly how Task 13's `ShotGraphCubit` calls them.
