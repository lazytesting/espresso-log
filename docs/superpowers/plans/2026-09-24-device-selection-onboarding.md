# Device Selection & Onboarding Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace compile-time `--dart-define` device selection with a user-facing, runtime choice: an onboarding flow on first launch, startup/resume connection checks with a non-blocking failure banner, and a Settings screen that can change the selected scale/pressure device at any time without restarting the app.

**Architecture:** Brand identity moves entirely into `lib/data/` as `Type`-keyed factory registries (no brand-naming enum, no domain knowledge of vendors). A single `DeviceSelectionCubit` persists "which `Type` is selected per role" via a new `DeviceSelectionService` (SharedPreferences-backed). `main.dart`'s `MyApp` becomes a thin switch between an always-mounted `DeviceScopedApp` (keyed by the resolved selection, or a stable placeholder key while onboarding is incomplete) that owns the real repositories, rules, and cubits for that selection — so changing the selection tears down and rebuilds that subtree instead of requiring per-cubit swap methods. A shared `DeviceConfigModal` widget (with two thin per-role wrappers) is reused identically by onboarding and by Settings.

**Tech Stack:** Flutter, `flutter_bloc`/`bloc_test`, `mockito` (`@GenerateNiceMocks`), `shared_preferences`, `flutter_blue_plus`, `provider`, `go_router`.

**Spec:** `docs/superpowers/specs/2026-09-23-device-selection-onboarding-design.md`

## Deviations from the spec

- The spec's `BluetoothDeviceMixin` sketch also mentions a `connect()` method
  and a `Stream<DeviceConnectionStatus>`. Neither is implemented: `init()`
  (already on `ScaleRepository`/`PressureRepository`) already serves as the
  connect verb everywhere in the codebase, and nothing in this plan consumes
  a status stream — `ConnectionCubit`'s existing sealed `ConnectionState`
  already surfaces connect/fail/pause status to the UI. Adding either would
  be unused surface area (YAGNI). If a future feature needs per-device
  status independent of the aggregate `ConnectionCubit` state, add the
  stream then.

## Global Constraints

- Domain (`lib/domain/`) never imports `flutter_blue_plus` or `shared_preferences` — brand `Type`s, registries, and `SharedPreferences` access live in `lib/data/`.
- No new enum of device brands/types is introduced anywhere; selection is expressed via the concrete service classes' `Type`.
- `BluetoothDeviceMixin.isBatteryPowered` must be `false` for `DecentScaleService`/`MockScaleService` (USB-powered scale) and `true` for `BookooPressureService` (unchanged from today); idle-disconnect must only ever act on `isBatteryPowered == true` devices.
- Mocked roles (`USE_MOCK_SCALE`/`USE_MOCK_PRESSURE` dart-defines) are auto-selected and never shown in onboarding.
- No new `go_router` route is added for onboarding.
- Settings must remain fully reachable and interactive regardless of connection state.
- Follow this repo's existing test conventions: `mockito` + `@GenerateNiceMocks` for interface mocks (regenerate via `fvm dart run build_runner build --delete-conflicting-outputs`), `bloc_test` for cubits, `flutter_test`'s `WidgetTester` for widgets.

## Review Focus

- A persisted device-type name that no longer matches any registry entry (e.g. a brand removed in a later app version) must fall back to "unresolved" and re-trigger onboarding, not crash the app on startup.
- A scan/connect attempt during onboarding or Settings that times out must present Retry/Back, never leave the user stuck on an unbounded spinner.
- Idle-triggered disconnect must never act on the (USB-powered) scale — only genuinely battery-powered devices.
- A failed `connect()`/`reconnect()` must emit a state the UI can show as a dismissible error, never throw uncaught or hang the app.
- Re-selecting the device that is already active (no actual change) must not tear down the running app or cause a reconnect storm.

---

## Task 1: Generalize `BatteryDeviceMixin` into `BluetoothDeviceMixin`

**Files:**
- Create: `lib/domain/telemetry/bluetooth_device_mixin.dart`
- Delete: `lib/domain/telemetry/battery_device_mixin.dart`
- Modify: `lib/data/pressure/bookoo_pressure_service.dart`
- Modify: `lib/data/pressure/mock_pressure_service.dart`
- Test: `test/data/pressure/bookoo_pressure_service_test.dart`
- Test: `test/data/pressure/mock_pressure_service_test.dart`

**Interfaces:**
- Produces: `mixin BluetoothDeviceMixin { Future<void> reconnect(); Future<void> disconnect(); bool get isBatteryPowered; }` — used by Task 2 (`ConnectionCubit`) and Task 3 (`DecentScaleService`/`MockScaleService`).

- [ ] **Step 1: Write the failing tests**

```dart
// test/data/pressure/bookoo_pressure_service_test.dart
import 'package:espresso_log/data/pressure/bookoo_pressure_service.dart';
import 'package:espresso_log/domain/telemetry/bluetooth_device_mixin.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:talker_flutter/talker_flutter.dart';

import 'package:espresso_log/data/bluetooth/bluetooth_devices_service.dart';

@GenerateNiceMocks([MockSpec<BluetoothDevicesService>(), MockSpec<Talker>()])
import 'bookoo_pressure_service_test.mocks.dart';

void main() {
  test('is a BluetoothDeviceMixin and reports battery-powered', () {
    final service = BookooPressureService(
      MockBluetoothDevicesService(),
      MockTalker(),
    );

    expect(service, isA<BluetoothDeviceMixin>());
    expect(service.isBatteryPowered, isTrue);
  });
}
```

```dart
// test/data/pressure/mock_pressure_service_test.dart
import 'package:espresso_log/data/pressure/mock_pressure_service.dart';
import 'package:espresso_log/domain/telemetry/bluetooth_device_mixin.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('is a BluetoothDeviceMixin and reports not battery-powered', () {
    final service = MockPressureService();

    expect(service, isA<BluetoothDeviceMixin>());
    expect(service.isBatteryPowered, isFalse);
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `fvm flutter test test/data/pressure/bookoo_pressure_service_test.dart test/data/pressure/mock_pressure_service_test.dart`
Expected: FAIL — `bluetooth_device_mixin.dart` doesn't exist yet, `BookooPressureService`/`MockPressureService` don't have `isBatteryPowered`.

- [ ] **Step 3: Create the new mixin**

```dart
// lib/domain/telemetry/bluetooth_device_mixin.dart
mixin BluetoothDeviceMixin {
  Future<void> reconnect();
  Future<void> disconnect();
  bool get isBatteryPowered;
}
```

- [ ] **Step 4: Delete the old mixin file**

```bash
git rm lib/domain/telemetry/battery_device_mixin.dart
```

- [ ] **Step 5: Update `BookooPressureService`**

In `lib/data/pressure/bookoo_pressure_service.dart`, replace the import and mixin use:

```dart
import 'package:espresso_log/domain/telemetry/bluetooth_device_mixin.dart';
```

```dart
class BookooPressureService
    with BluetoothDeviceMixin
    implements PressureRepository {
```

Add, alongside the existing `reconnect()`/`disconnect()` overrides:

```dart
  @override
  bool get isBatteryPowered => true;
```

- [ ] **Step 6: Update `MockPressureService`**

In `lib/data/pressure/mock_pressure_service.dart`, same import/mixin swap:

```dart
import 'package:espresso_log/domain/telemetry/bluetooth_device_mixin.dart';
```

```dart
class MockPressureService
    with BluetoothDeviceMixin
    implements PressureRepository {
```

Add:

```dart
  @override
  bool get isBatteryPowered => false;
```

- [ ] **Step 7: Regenerate mocks and run tests**

```bash
fvm dart run build_runner build --delete-conflicting-outputs
fvm flutter test test/data/pressure/bookoo_pressure_service_test.dart test/data/pressure/mock_pressure_service_test.dart
```
Expected: PASS

- [ ] **Step 8: Run full analyzer to catch remaining `BatteryDeviceMixin` references**

```bash
fvm flutter analyze
```
Expected: no errors. Fix any remaining `BatteryDeviceMixin` references reported (there should be none outside `ConnectionCubit`, which Task 2 handles).

- [ ] **Step 9: Commit**

```bash
git add lib/domain/telemetry/bluetooth_device_mixin.dart lib/data/pressure/bookoo_pressure_service.dart lib/data/pressure/mock_pressure_service.dart test/data/pressure/bookoo_pressure_service_test.dart test/data/pressure/bookoo_pressure_service_test.mocks.dart test/data/pressure/mock_pressure_service_test.dart
git commit -m "Generalize BatteryDeviceMixin into BluetoothDeviceMixin"
```

---

## Task 2: `ConnectionCubit` — battery-gated idle-disconnect and failure states

**Files:**
- Modify: `lib/ui/home/device_connection/connection_cubit.dart`
- Modify: `lib/ui/home/device_connection/connection_state.dart`
- Test: `test/ui/home/device_connection/connection_cubit_test.dart`

**Interfaces:**
- Consumes: `BluetoothDeviceMixin` (Task 1) — `reconnect()`, `disconnect()`, `isBatteryPowered`.
- Produces: `ConnectionFailed` state (new), used by Task 9 (`ConnectionModalWrapper`).

- [ ] **Step 1: Write the failing tests**

```dart
// test/ui/home/device_connection/connection_cubit_test.dart
import 'package:bloc_test/bloc_test.dart';
import 'package:espresso_log/domain/telemetry/bluetooth_device_mixin.dart';
import 'package:espresso_log/domain/telemetry/pressure_repository.dart';
import 'package:espresso_log/domain/telemetry/scale_repository.dart';
import 'package:espresso_log/ui/home/device_connection/connection_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeScaleRepository extends ScaleRepository {
  bool shouldFailInit = false;

  @override
  String get displayName => 'Fake Scale';

  @override
  Future<void> init() async {
    if (shouldFailInit) throw Exception('scale unreachable');
  }
}

// Mirrors DecentScaleService: implements BluetoothDeviceMixin (so it can be
// reconnected on resume) but is USB-powered, so isBatteryPowered is false
// and idle-disconnect must never call disconnect() on it.
class _FakeUsbScaleRepository extends ScaleRepository with BluetoothDeviceMixin {
  bool disconnectCalled = false;

  @override
  String get displayName => 'Fake USB Scale';

  @override
  bool get isBatteryPowered => false;

  @override
  Future<void> reconnect() async {}

  @override
  Future<void> disconnect() async {
    disconnectCalled = true;
  }
}

class _FakeBatteryPressureRepository extends PressureRepository
    with BluetoothDeviceMixin {
  bool reconnectCalled = false;
  bool disconnectCalled = false;
  bool shouldFailReconnect = false;
  bool shouldFailInit = false;

  @override
  String get displayName => 'Fake Pressure';

  @override
  bool get isBatteryPowered => true;

  @override
  void dispose() {}

  @override
  Future<void> init() async {
    if (shouldFailInit) throw Exception('pressure sensor unreachable');
  }

  @override
  Future<void> reconnect() async {
    reconnectCalled = true;
    if (shouldFailReconnect) throw Exception('pressure sensor unreachable');
  }

  @override
  Future<void> disconnect() async {
    disconnectCalled = true;
  }
}

void main() {
  group('connect()', () {
    blocTest<ConnectionCubit, ConnectionState>(
      'emits Connecting then Established on success',
      build: () =>
          ConnectionCubit(_FakeScaleRepository(), _FakeBatteryPressureRepository()),
      act: (cubit) => cubit.connect(),
      expect: () => [isA<ConnectionConnecting>(), isA<ConnectionEstablished>()],
    );

    blocTest<ConnectionCubit, ConnectionState>(
      'emits Connecting then Failed when a device init throws',
      build: () => ConnectionCubit(
        _FakeScaleRepository()..shouldFailInit = true,
        _FakeBatteryPressureRepository(),
      ),
      act: (cubit) => cubit.connect(),
      expect: () => [isA<ConnectionConnecting>(), isA<ConnectionFailed>()],
    );
  });

  group('reconnect()', () {
    blocTest<ConnectionCubit, ConnectionState>(
      'emits Failed when a battery device fails to reconnect',
      build: () => ConnectionCubit(
        _FakeScaleRepository(),
        _FakeBatteryPressureRepository()..shouldFailReconnect = true,
      ),
      act: (cubit) => cubit.reconnect(),
      expect: () => [isA<ConnectionConnecting>(), isA<ConnectionFailed>()],
    );
  });

  group('disconnect() idle behavior', () {
    test('only disconnects battery-powered devices', () async {
      final pressure = _FakeBatteryPressureRepository();
      final cubit = ConnectionCubit(_FakeScaleRepository(), pressure);

      await cubit.disconnect();

      expect(pressure.disconnectCalled, isTrue);
    });

    test('does not disconnect a non-battery-powered scale', () async {
      final scale = _FakeUsbScaleRepository();
      final pressure = _FakeBatteryPressureRepository();
      final cubit = ConnectionCubit(scale, pressure);

      await cubit.disconnect();

      expect(scale.disconnectCalled, isFalse);
      expect(pressure.disconnectCalled, isTrue);
    });
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `fvm flutter test test/ui/home/device_connection/connection_cubit_test.dart`
Expected: FAIL — `ConnectionFailed` doesn't exist; `connect()`/`reconnect()` don't catch errors yet.

- [ ] **Step 3: Add the `ConnectionFailed` state**

```dart
// lib/ui/home/device_connection/connection_state.dart
part of 'connection_cubit.dart';

sealed class ConnectionState {}

final class ConnectionInitial extends ConnectionState {}

final class ConnectionConnecting extends ConnectionState {}

final class ConnectionEstablished extends ConnectionState {}

final class ConnectionPaused extends ConnectionState {}

final class ConnectionFailed extends ConnectionState {}
```

- [ ] **Step 4: Rewrite `ConnectionCubit`**

```dart
// lib/ui/home/device_connection/connection_cubit.dart
import 'package:espresso_log/domain/telemetry/bluetooth_device_mixin.dart';
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
    try {
      if (_scaleRepository is BluetoothDeviceMixin) {
        await (_scaleRepository as BluetoothDeviceMixin).reconnect();
      }
      if (_pressureRepository is BluetoothDeviceMixin) {
        await (_pressureRepository as BluetoothDeviceMixin).reconnect();
      }
      emit(ConnectionEstablished());
    } catch (_) {
      emit(ConnectionFailed());
    }
  }

  Future<void> disconnect() async {
    final scaleIsBattery =
        _scaleRepository is BluetoothDeviceMixin &&
        (_scaleRepository as BluetoothDeviceMixin).isBatteryPowered;
    final pressureIsBattery =
        _pressureRepository is BluetoothDeviceMixin &&
        (_pressureRepository as BluetoothDeviceMixin).isBatteryPowered;

    if (scaleIsBattery || pressureIsBattery) {
      emit(ConnectionPaused());
    }

    if (scaleIsBattery) {
      await (_scaleRepository as BluetoothDeviceMixin).disconnect();
    }
    if (pressureIsBattery) {
      await (_pressureRepository as BluetoothDeviceMixin).disconnect();
    }
  }

  Future<void> connect() async {
    emit(ConnectionConnecting());
    try {
      await Future.wait([_scaleRepository.init(), _pressureRepository.init()]);
      emit(ConnectionEstablished());
    } catch (_) {
      emit(ConnectionFailed());
    }
  }
}
```

- [ ] **Step 5: Run tests to verify they pass**

Run: `fvm flutter test test/ui/home/device_connection/connection_cubit_test.dart`
Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add lib/ui/home/device_connection/connection_cubit.dart lib/ui/home/device_connection/connection_state.dart test/ui/home/device_connection/connection_cubit_test.dart
git commit -m "Add ConnectionFailed state and gate idle-disconnect on isBatteryPowered"
```

---

## Task 3: Adopt `BluetoothDeviceMixin` on the scale services

**Files:**
- Modify: `lib/data/scale/decent_scale_service.dart`
- Modify: `lib/data/scale/mock_scale_service.dart`
- Test: `test/data/scale/decent_scale_service_test.dart`
- Test: `test/data/scale/mock_scale_service_test.dart`

**Interfaces:**
- Consumes: `BluetoothDeviceMixin` (Task 1).
- Produces: `DecentScaleService`/`MockScaleService` now satisfy `BluetoothDeviceMixin`, needed by Task 6's registries (factory return type stays `ScaleRepository`, but `ConnectionCubit`'s `is BluetoothDeviceMixin` checks now also match these).

- [ ] **Step 1: Write the failing tests**

```dart
// test/data/scale/decent_scale_service_test.dart
import 'package:espresso_log/data/bluetooth/bluetooth_devices_service.dart';
import 'package:espresso_log/data/scale/decent_scale_service.dart';
import 'package:espresso_log/domain/telemetry/bluetooth_device_mixin.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:talker_flutter/talker_flutter.dart';

@GenerateNiceMocks([MockSpec<BluetoothDevicesService>(), MockSpec<Talker>()])
import 'decent_scale_service_test.mocks.dart';

void main() {
  test('is a BluetoothDeviceMixin and is not battery-powered (USB-powered)', () {
    final service = DecentScaleService(
      MockBluetoothDevicesService(),
      MockTalker(),
    );

    expect(service, isA<BluetoothDeviceMixin>());
    expect(service.isBatteryPowered, isFalse);
  });
}
```

```dart
// test/data/scale/mock_scale_service_test.dart
import 'package:espresso_log/data/scale/mock_scale_service.dart';
import 'package:espresso_log/domain/telemetry/bluetooth_device_mixin.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('is a BluetoothDeviceMixin and is not battery-powered', () {
    final service = MockScaleService();

    expect(service, isA<BluetoothDeviceMixin>());
    expect(service.isBatteryPowered, isFalse);
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `fvm flutter test test/data/scale/decent_scale_service_test.dart test/data/scale/mock_scale_service_test.dart`
Expected: FAIL — neither class implements `BluetoothDeviceMixin` yet.

- [ ] **Step 3: Update `DecentScaleService`**

In `lib/data/scale/decent_scale_service.dart`, add the import and mixin, plus the three new members (place near the other overrides, e.g. after `tareCommand()`):

```dart
import 'package:espresso_log/domain/telemetry/bluetooth_device_mixin.dart';
```

```dart
class DecentScaleService with BluetoothDeviceMixin implements ScaleRepository {
```

```dart
  @override
  bool get isBatteryPowered => false;

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
```

- [ ] **Step 4: Update `MockScaleService`**

In `lib/data/scale/mock_scale_service.dart`:

```dart
import 'package:espresso_log/domain/telemetry/bluetooth_device_mixin.dart';
```

```dart
class MockScaleService with BluetoothDeviceMixin implements ScaleRepository {
```

```dart
  @override
  bool get isBatteryPowered => false;

  @override
  Future<void> reconnect() async {}

  @override
  Future<void> disconnect() async {}
```

- [ ] **Step 5: Regenerate mocks and run tests**

```bash
fvm dart run build_runner build --delete-conflicting-outputs
fvm flutter test test/data/scale/decent_scale_service_test.dart test/data/scale/mock_scale_service_test.dart
```
Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add lib/data/scale/decent_scale_service.dart lib/data/scale/mock_scale_service.dart test/data/scale/decent_scale_service_test.dart test/data/scale/decent_scale_service_test.mocks.dart test/data/scale/mock_scale_service_test.dart
git commit -m "Adopt BluetoothDeviceMixin on scale services (USB-powered, no idle-disconnect)"
```

---

## Task 4: `displayName` on `ScaleRepository`/`PressureRepository`

**Files:**
- Modify: `lib/domain/telemetry/scale_repository.dart`
- Modify: `lib/domain/telemetry/pressure_repository.dart`
- Modify: `lib/data/scale/decent_scale_service.dart`
- Modify: `lib/data/scale/mock_scale_service.dart`
- Modify: `lib/data/pressure/bookoo_pressure_service.dart`
- Modify: `lib/data/pressure/mock_pressure_service.dart`
- Test: `test/data/scale/decent_scale_service_test.dart`
- Test: `test/data/scale/mock_scale_service_test.dart`
- Test: `test/data/pressure/bookoo_pressure_service_test.dart`
- Test: `test/data/pressure/mock_pressure_service_test.dart`

**Interfaces:**
- Produces: `String get displayName` on both repository interfaces, needed by Task 6's registries and Task 10's `DeviceConfigModal`.

- [ ] **Step 1: Add failing assertions to the four existing test files from Tasks 1 & 3**

Add to `test/data/scale/decent_scale_service_test.dart`'s existing test body:

```dart
    expect(service.displayName, 'Decent Scale');
```

Add to `test/data/scale/mock_scale_service_test.dart`:

```dart
    expect(service.displayName, 'Mock Scale');
```

Add to `test/data/pressure/bookoo_pressure_service_test.dart`:

```dart
    expect(service.displayName, 'Bookoo Pressure Sensor');
```

Add to `test/data/pressure/mock_pressure_service_test.dart`:

```dart
    expect(service.displayName, 'Mock Pressure Sensor');
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `fvm flutter test test/data/scale test/data/pressure`
Expected: FAIL — `displayName` getter doesn't exist.

- [ ] **Step 3: Add the abstract getter to both domain interfaces**

```dart
// lib/domain/telemetry/scale_repository.dart
import 'package:espresso_log/domain/telemetry/scale_event.dart';

abstract class ScaleRepository {
  Stream<ScaleEvent> stream = const Stream.empty();

  String get displayName;

  Future<void> init() async {}

  Future<void> tareCommand() async {}
}
```

```dart
// lib/domain/telemetry/pressure_repository.dart
import 'package:espresso_log/domain/telemetry/pressure_reading.dart';

abstract class PressureRepository {
  Stream<PressureReading> stream = const Stream.empty();

  String get displayName;

  Future<void> init() async {}

  void dispose();
}
```

- [ ] **Step 4: Implement it on each concrete class**

`lib/data/scale/decent_scale_service.dart`:
```dart
  @override
  String get displayName => 'Decent Scale';
```

`lib/data/scale/mock_scale_service.dart`:
```dart
  @override
  String get displayName => 'Mock Scale';
```

`lib/data/pressure/bookoo_pressure_service.dart`:
```dart
  @override
  String get displayName => 'Bookoo Pressure Sensor';
```

`lib/data/pressure/mock_pressure_service.dart`:
```dart
  @override
  String get displayName => 'Mock Pressure Sensor';
```

- [ ] **Step 5: Run full test suite and analyzer**

```bash
fvm flutter analyze
fvm flutter test
```
Expected: PASS everywhere. (`AutoTareRule`/`AutoStartStopRule`'s mocked-repository tests continue to pass since `NiceMock` auto-stubs unimplemented getters.)

- [ ] **Step 6: Commit**

```bash
git add lib/domain/telemetry/scale_repository.dart lib/domain/telemetry/pressure_repository.dart lib/data/scale/decent_scale_service.dart lib/data/scale/mock_scale_service.dart lib/data/pressure/bookoo_pressure_service.dart lib/data/pressure/mock_pressure_service.dart test/data/scale/decent_scale_service_test.dart test/data/scale/mock_scale_service_test.dart test/data/pressure/bookoo_pressure_service_test.dart test/data/pressure/mock_pressure_service_test.dart
git commit -m "Add displayName to ScaleRepository/PressureRepository and implementations"
```

---

## Task 5: Persist the paired device ID in `BluetoothDevicesService`

**Files:**
- Modify: `lib/data/bluetooth/bluetooth_devices_service.dart`

**Interfaces:**
- No new public API — `connectToDevice(String searchName)` behavior changes internally so a device found via scan gets its ID written to `SharedPreferences`, matching the read path that already exists at line 18.

This fixes a pre-existing gap: nothing today writes the `SharedPreferences` key that `connectToDevice` reads on line 18, so a fresh pairing is never remembered across restarts. `FlutterBluePlus` is a plugin with static, platform-channel-backed APIs; this codebase has no existing test harness for it (no tests exist for this class today), so this task is verified manually rather than with a new unit test, consistent with the file's current (zero) coverage.

- [ ] **Step 1: Add the write path**

In `lib/data/bluetooth/bluetooth_devices_service.dart`, `connectToDevice` currently returns early via three paths (already-stored ID, existing scan result, fresh scan result). Add persistence to the two paths that don't already come from storage:

```dart
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
      await prefs.setString(searchName, scanResults.first.device.remoteId.str);
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
    await prefs.setString(searchName, scanResult2.device.remoteId.str);
    return scanResult2.device;
  }
```

- [ ] **Step 2: Manual verification**

Run: `fvm flutter run` against real hardware (or `--dart-define USE_MOCK_SCALE=true` for the unaffected mock path), pair a device via onboarding once this plan's later tasks land, fully restart the app, and confirm it reconnects using the stored ID rather than re-scanning (visible in the Talker log viewer at `/settings/log`, which logs `BluetoothAdapterState` changes).

- [ ] **Step 3: Commit**

```bash
git add lib/data/bluetooth/bluetooth_devices_service.dart
git commit -m "Persist paired device ID after a successful BLE connect"
```

---

## Task 6: Device-option registries

**Files:**
- Create: `lib/data/scale/scale_device_options.dart`
- Create: `lib/data/pressure/pressure_device_options.dart`
- Test: `test/data/scale/scale_device_options_test.dart`
- Test: `test/data/pressure/pressure_device_options_test.dart`

**Interfaces:**
- Produces:
  - `typedef ScaleRepositoryFactory = ScaleRepository Function(BluetoothDevicesService, Talker);`
  - `final Map<Type, ScaleRepositoryFactory> scaleDeviceOptions;`
  - `typedef PressureRepositoryFactory = PressureRepository Function(BluetoothDevicesService, Talker);`
  - `final Map<Type, PressureRepositoryFactory> pressureDeviceOptions;`
  - Consumed by Task 8 (`DeviceSelectionCubit`), Task 10 (`ScaleConfigModal`/`PressureConfigModal`), Task 11 (`DeviceScopedApp`), Task 12 (`SettingsScreen`).

- [ ] **Step 1: Write the failing tests**

```dart
// test/data/scale/scale_device_options_test.dart
import 'package:espresso_log/data/bluetooth/bluetooth_devices_service.dart';
import 'package:espresso_log/data/scale/decent_scale_service.dart';
import 'package:espresso_log/data/scale/mock_scale_service.dart';
import 'package:espresso_log/data/scale/scale_device_options.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:talker_flutter/talker_flutter.dart';

@GenerateNiceMocks([MockSpec<BluetoothDevicesService>(), MockSpec<Talker>()])
import 'scale_device_options_test.mocks.dart';

void main() {
  test('registers Decent and Mock scale options with correct display names', () {
    final bluetoothService = MockBluetoothDevicesService();
    final talker = MockTalker();

    expect(
      scaleDeviceOptions.keys,
      containsAll([DecentScaleService, MockScaleService]),
    );

    final decent = scaleDeviceOptions[DecentScaleService]!(
      bluetoothService,
      talker,
    );
    expect(decent, isA<DecentScaleService>());
    expect(decent.displayName, 'Decent Scale');

    final mock = scaleDeviceOptions[MockScaleService]!(
      bluetoothService,
      talker,
    );
    expect(mock, isA<MockScaleService>());
    expect(mock.displayName, 'Mock Scale');
  });
}
```

```dart
// test/data/pressure/pressure_device_options_test.dart
import 'package:espresso_log/data/bluetooth/bluetooth_devices_service.dart';
import 'package:espresso_log/data/pressure/bookoo_pressure_service.dart';
import 'package:espresso_log/data/pressure/mock_pressure_service.dart';
import 'package:espresso_log/data/pressure/pressure_device_options.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:talker_flutter/talker_flutter.dart';

@GenerateNiceMocks([MockSpec<BluetoothDevicesService>(), MockSpec<Talker>()])
import 'pressure_device_options_test.mocks.dart';

void main() {
  test('registers Bookoo and Mock pressure options with correct display names', () {
    final bluetoothService = MockBluetoothDevicesService();
    final talker = MockTalker();

    expect(
      pressureDeviceOptions.keys,
      containsAll([BookooPressureService, MockPressureService]),
    );

    final bookoo = pressureDeviceOptions[BookooPressureService]!(
      bluetoothService,
      talker,
    );
    expect(bookoo, isA<BookooPressureService>());
    expect(bookoo.displayName, 'Bookoo Pressure Sensor');

    final mock = pressureDeviceOptions[MockPressureService]!(
      bluetoothService,
      talker,
    );
    expect(mock, isA<MockPressureService>());
    expect(mock.displayName, 'Mock Pressure Sensor');
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `fvm flutter test test/data/scale/scale_device_options_test.dart test/data/pressure/pressure_device_options_test.dart`
Expected: FAIL — files don't exist.

- [ ] **Step 3: Create the registries**

```dart
// lib/data/scale/scale_device_options.dart
import 'package:espresso_log/data/bluetooth/bluetooth_devices_service.dart';
import 'package:espresso_log/data/scale/decent_scale_service.dart';
import 'package:espresso_log/data/scale/mock_scale_service.dart';
import 'package:espresso_log/domain/telemetry/scale_repository.dart';
import 'package:talker_flutter/talker_flutter.dart';

typedef ScaleRepositoryFactory =
    ScaleRepository Function(BluetoothDevicesService bluetoothService, Talker talker);

final Map<Type, ScaleRepositoryFactory> scaleDeviceOptions = {
  DecentScaleService: (bluetoothService, talker) =>
      DecentScaleService(bluetoothService, talker),
  MockScaleService: (bluetoothService, talker) => MockScaleService(),
};
```

```dart
// lib/data/pressure/pressure_device_options.dart
import 'package:espresso_log/data/bluetooth/bluetooth_devices_service.dart';
import 'package:espresso_log/data/pressure/bookoo_pressure_service.dart';
import 'package:espresso_log/data/pressure/mock_pressure_service.dart';
import 'package:espresso_log/domain/telemetry/pressure_repository.dart';
import 'package:talker_flutter/talker_flutter.dart';

typedef PressureRepositoryFactory =
    PressureRepository Function(BluetoothDevicesService bluetoothService, Talker talker);

final Map<Type, PressureRepositoryFactory> pressureDeviceOptions = {
  BookooPressureService: (bluetoothService, talker) =>
      BookooPressureService(bluetoothService, talker),
  MockPressureService: (bluetoothService, talker) => MockPressureService(),
};
```

- [ ] **Step 4: Regenerate mocks and run tests**

```bash
fvm dart run build_runner build --delete-conflicting-outputs
fvm flutter test test/data/scale/scale_device_options_test.dart test/data/pressure/pressure_device_options_test.dart
```
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/data/scale/scale_device_options.dart lib/data/pressure/pressure_device_options.dart test/data/scale/scale_device_options_test.dart test/data/scale/scale_device_options_test.mocks.dart test/data/pressure/pressure_device_options_test.dart test/data/pressure/pressure_device_options_test.mocks.dart
git commit -m "Add Type-keyed device-option registries for scale and pressure"
```

---

## Task 7: `DeviceSelectionService`

**Files:**
- Create: `lib/data/device_selection/device_selection_service.dart`
- Test: `test/data/device_selection/device_selection_service_test.dart`

**Interfaces:**
- Produces:
  - `class DeviceSelectionService { Future<String?> getSelectedScaleTypeName(); Future<void> setSelectedScaleTypeName(String typeName); Future<String?> getSelectedPressureTypeName(); Future<void> setSelectedPressureTypeName(String typeName); }`
  - Consumed by Task 8 (`DeviceSelectionCubit`).

- [ ] **Step 1: Write the failing test**

```dart
// test/data/device_selection/device_selection_service_test.dart
import 'package:espresso_log/data/device_selection/device_selection_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('scale type persists across get/set', () async {
    final service = DeviceSelectionService();

    expect(await service.getSelectedScaleTypeName(), isNull);

    await service.setSelectedScaleTypeName('DecentScaleService');

    expect(await service.getSelectedScaleTypeName(), 'DecentScaleService');
  });

  test('pressure type persists across get/set', () async {
    final service = DeviceSelectionService();

    expect(await service.getSelectedPressureTypeName(), isNull);

    await service.setSelectedPressureTypeName('BookooPressureService');

    expect(await service.getSelectedPressureTypeName(), 'BookooPressureService');
  });

  test('scale and pressure selections do not collide', () async {
    final service = DeviceSelectionService();

    await service.setSelectedScaleTypeName('MockScaleService');
    await service.setSelectedPressureTypeName('MockPressureService');

    expect(await service.getSelectedScaleTypeName(), 'MockScaleService');
    expect(await service.getSelectedPressureTypeName(), 'MockPressureService');
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `fvm flutter test test/data/device_selection/device_selection_service_test.dart`
Expected: FAIL — file doesn't exist.

- [ ] **Step 3: Implement `DeviceSelectionService`**

```dart
// lib/data/device_selection/device_selection_service.dart
import 'package:shared_preferences/shared_preferences.dart';

class DeviceSelectionService {
  static const _scaleTypeKey = 'selected_scale_type';
  static const _pressureTypeKey = 'selected_pressure_type';

  Future<String?> getSelectedScaleTypeName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_scaleTypeKey);
  }

  Future<void> setSelectedScaleTypeName(String typeName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_scaleTypeKey, typeName);
  }

  Future<String?> getSelectedPressureTypeName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_pressureTypeKey);
  }

  Future<void> setSelectedPressureTypeName(String typeName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pressureTypeKey, typeName);
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `fvm flutter test test/data/device_selection/device_selection_service_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/data/device_selection/device_selection_service.dart test/data/device_selection/device_selection_service_test.dart
git commit -m "Add DeviceSelectionService for persisting selected device types"
```

---

## Task 8: `DeviceSelectionCubit`

**Files:**
- Create: `lib/ui/device_selection/device_selection_cubit.dart`
- Create: `lib/ui/device_selection/device_selection_state.dart`
- Test: `test/ui/device_selection/device_selection_cubit_test.dart`

**Interfaces:**
- Consumes: `DeviceSelectionService` (Task 7), `scaleDeviceOptions`/`pressureDeviceOptions` (Task 6).
- Produces:
  - `class DeviceSelectionState extends Equatable { final Type? scaleType; final Type? pressureType; bool get isResolved; }`
  - `class DeviceSelectionCubit extends Cubit<DeviceSelectionState> { DeviceSelectionCubit(DeviceSelectionService, {required bool useMockScale, required bool useMockPressure}); Future<void> load(); Future<void> selectScaleType(Type type); Future<void> selectPressureType(Type type); }`
  - Consumed by Task 9 (n/a), Task 10 (`ScaleConfigModal`/`PressureConfigModal`), Task 11 (`main.dart`/`DeviceScopedApp`), Task 12 (`SettingsScreen`).

- [ ] **Step 1: Write the failing tests**

```dart
// test/ui/device_selection/device_selection_cubit_test.dart
import 'package:bloc_test/bloc_test.dart';
import 'package:espresso_log/data/device_selection/device_selection_service.dart';
import 'package:espresso_log/data/scale/decent_scale_service.dart';
import 'package:espresso_log/data/scale/mock_scale_service.dart';
import 'package:espresso_log/data/pressure/bookoo_pressure_service.dart';
import 'package:espresso_log/data/pressure/mock_pressure_service.dart';
import 'package:espresso_log/ui/device_selection/device_selection_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

@GenerateNiceMocks([MockSpec<DeviceSelectionService>()])
import 'device_selection_cubit_test.mocks.dart';

void main() {
  group('load()', () {
    blocTest<DeviceSelectionCubit, DeviceSelectionState>(
      'resolves persisted selections',
      build: () {
        final service = MockDeviceSelectionService();
        when(
          service.getSelectedScaleTypeName(),
        ).thenAnswer((_) async => 'DecentScaleService');
        when(
          service.getSelectedPressureTypeName(),
        ).thenAnswer((_) async => 'BookooPressureService');
        return DeviceSelectionCubit(
          service,
          useMockScale: false,
          useMockPressure: false,
        );
      },
      act: (cubit) => cubit.load(),
      expect: () => [
        const DeviceSelectionState(
          scaleType: DecentScaleService,
          pressureType: BookooPressureService,
        ),
      ],
    );

    blocTest<DeviceSelectionCubit, DeviceSelectionState>(
      'auto-selects mock roles without reading persistence',
      build: () {
        final service = MockDeviceSelectionService();
        return DeviceSelectionCubit(
          service,
          useMockScale: true,
          useMockPressure: true,
        );
      },
      act: (cubit) => cubit.load(),
      expect: () => [
        const DeviceSelectionState(
          scaleType: MockScaleService,
          pressureType: MockPressureService,
        ),
      ],
    );

    blocTest<DeviceSelectionCubit, DeviceSelectionState>(
      'falls back to unresolved when the persisted type name is unknown',
      build: () {
        final service = MockDeviceSelectionService();
        when(
          service.getSelectedScaleTypeName(),
        ).thenAnswer((_) async => 'SomeRemovedBrandService');
        when(
          service.getSelectedPressureTypeName(),
        ).thenAnswer((_) async => 'BookooPressureService');
        return DeviceSelectionCubit(
          service,
          useMockScale: false,
          useMockPressure: false,
        );
      },
      act: (cubit) => cubit.load(),
      expect: () => [
        const DeviceSelectionState(
          scaleType: null,
          pressureType: BookooPressureService,
        ),
      ],
    );
  });

  group('selectScaleType()/selectPressureType()', () {
    blocTest<DeviceSelectionCubit, DeviceSelectionState>(
      'persists and emits the new scale selection',
      build: () => DeviceSelectionCubit(
        MockDeviceSelectionService(),
        useMockScale: false,
        useMockPressure: false,
      ),
      act: (cubit) => cubit.selectScaleType(DecentScaleService),
      expect: () => [
        const DeviceSelectionState(
          scaleType: DecentScaleService,
          pressureType: null,
        ),
      ],
    );

    blocTest<DeviceSelectionCubit, DeviceSelectionState>(
      'selecting the already-active type is a harmless no-op re-emit',
      build: () => DeviceSelectionCubit(
        MockDeviceSelectionService(),
        useMockScale: false,
        useMockPressure: false,
      ),
      seed: () => const DeviceSelectionState(
        scaleType: DecentScaleService,
        pressureType: null,
      ),
      act: (cubit) => cubit.selectScaleType(DecentScaleService),
      expect: () => [
        const DeviceSelectionState(
          scaleType: DecentScaleService,
          pressureType: null,
        ),
      ],
    );
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `fvm flutter test test/ui/device_selection/device_selection_cubit_test.dart`
Expected: FAIL — files don't exist.

- [ ] **Step 3: Implement the state**

```dart
// lib/ui/device_selection/device_selection_state.dart
part of 'device_selection_cubit.dart';

class DeviceSelectionState extends Equatable {
  const DeviceSelectionState({required this.scaleType, required this.pressureType});

  final Type? scaleType;
  final Type? pressureType;

  bool get isResolved => scaleType != null && pressureType != null;

  DeviceSelectionState copyWithScaleType(Type type) =>
      DeviceSelectionState(scaleType: type, pressureType: pressureType);

  DeviceSelectionState copyWithPressureType(Type type) =>
      DeviceSelectionState(scaleType: scaleType, pressureType: type);

  @override
  List<Object?> get props => [scaleType, pressureType];
}
```

- [ ] **Step 4: Implement the cubit**

```dart
// lib/ui/device_selection/device_selection_cubit.dart
import 'package:equatable/equatable.dart';
import 'package:espresso_log/data/device_selection/device_selection_service.dart';
import 'package:espresso_log/data/pressure/pressure_device_options.dart';
import 'package:espresso_log/data/scale/scale_device_options.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'device_selection_state.dart';

class DeviceSelectionCubit extends Cubit<DeviceSelectionState> {
  DeviceSelectionCubit(
    this._deviceSelectionService, {
    required bool useMockScale,
    required bool useMockPressure,
  }) : _useMockScale = useMockScale,
       _useMockPressure = useMockPressure,
       super(const DeviceSelectionState(scaleType: null, pressureType: null));

  final DeviceSelectionService _deviceSelectionService;
  final bool _useMockScale;
  final bool _useMockPressure;

  Future<void> load() async {
    Type? scaleType;
    if (_useMockScale) {
      scaleType = scaleDeviceOptions.keys.firstWhere(
        (type) => type.toString() == 'MockScaleService',
      );
    } else {
      final name = await _deviceSelectionService.getSelectedScaleTypeName();
      scaleType = _resolveType(scaleDeviceOptions.keys, name);
    }

    Type? pressureType;
    if (_useMockPressure) {
      pressureType = pressureDeviceOptions.keys.firstWhere(
        (type) => type.toString() == 'MockPressureService',
      );
    } else {
      final name = await _deviceSelectionService.getSelectedPressureTypeName();
      pressureType = _resolveType(pressureDeviceOptions.keys, name);
    }

    emit(DeviceSelectionState(scaleType: scaleType, pressureType: pressureType));
  }

  Type? _resolveType(Iterable<Type> candidates, String? name) {
    if (name == null) return null;
    for (final type in candidates) {
      if (type.toString() == name) return type;
    }
    return null;
  }

  Future<void> selectScaleType(Type type) async {
    await _deviceSelectionService.setSelectedScaleTypeName(type.toString());
    emit(state.copyWithScaleType(type));
  }

  Future<void> selectPressureType(Type type) async {
    await _deviceSelectionService.setSelectedPressureTypeName(type.toString());
    emit(state.copyWithPressureType(type));
  }
}
```

- [ ] **Step 5: Regenerate mocks and run tests**

```bash
fvm dart run build_runner build --delete-conflicting-outputs
fvm flutter test test/ui/device_selection/device_selection_cubit_test.dart
```
Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add lib/ui/device_selection/device_selection_cubit.dart lib/ui/device_selection/device_selection_state.dart test/ui/device_selection/device_selection_cubit_test.dart test/ui/device_selection/device_selection_cubit_test.mocks.dart
git commit -m "Add DeviceSelectionCubit resolving mock/persisted/unknown selections"
```

---

## Task 9: Non-blocking failure banner in `ConnectionModalWrapper`

**Files:**
- Modify: `lib/ui/home/device_connection/connection_modal_wrapper.dart`
- Test: `test/ui/home/device_connection/connection_modal_wrapper_test.dart`

**Interfaces:**
- Consumes: `ConnectionFailed` state (Task 2).

- [ ] **Step 1: Write the failing test**

```dart
// test/ui/home/device_connection/connection_modal_wrapper_test.dart
import 'package:espresso_log/ui/home/device_connection/connection_cubit.dart';
import 'package:espresso_log/ui/home/device_connection/connection_modal_wrapper.dart';
import 'package:flutter/material.dart' hide ConnectionState;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeConnectionCubit extends Cubit<ConnectionState>
    implements ConnectionCubit {
  _FakeConnectionCubit() : super(ConnectionInitial());

  void emitFailed() => emit(ConnectionFailed());

  @override
  Future<void> connect() async {}
  @override
  Future<void> disconnect() async {}
  @override
  Future<void> reconnect() async {}
}

void main() {
  testWidgets('shows a dismissible banner on ConnectionFailed, not a blocking dialog', (
    tester,
  ) async {
    final navigatorKey = GlobalKey<NavigatorState>();
    final cubit = _FakeConnectionCubit();

    await tester.pumpWidget(
      BlocProvider<ConnectionCubit>.value(
        value: cubit,
        child: MaterialApp(
          navigatorKey: navigatorKey,
          home: ConnectionModalWrapper(
            navigatorKey: navigatorKey,
            child: const Scaffold(body: Text('Home')),
          ),
        ),
      ),
    );

    cubit.emitFailed();
    await tester.pump();

    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);
    // Settings/home content stays interactive underneath the banner.
    expect(find.text('Home'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `fvm flutter test test/ui/home/device_connection/connection_modal_wrapper_test.dart`
Expected: FAIL — `ConnectionFailed` currently falls into the `else` branch and shows a blocking `AlertDialog`.

- [ ] **Step 3: Update `ConnectionModalWrapper`**

```dart
// lib/ui/home/device_connection/connection_modal_wrapper.dart
import 'package:espresso_log/ui/home/device_connection/connection_cubit.dart';
import 'package:flutter/material.dart' hide ConnectionState;
import 'package:flutter_bloc/flutter_bloc.dart';

class ConnectionModalWrapper extends StatelessWidget {
  const ConnectionModalWrapper({
    super.key,
    required this.child,
    required this.navigatorKey,
  });

  final Widget child;
  final GlobalKey<NavigatorState> navigatorKey;

  void _dismissConnectionDialog() {
    final nav = navigatorKey.currentState;
    if (nav == null) return;

    nav.popUntil((route) {
      if (route.settings.name == 'connection_dialog') {
        nav.pop();
        return false;
      }
      return true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ConnectionCubit, ConnectionState>(
      listener: (context, state) async {
        if (state is ConnectionEstablished || state is ConnectionInitial) {
          _dismissConnectionDialog();
          return;
        }
        if (state is ConnectionFailed) {
          _dismissConnectionDialog();
          final messengerContext = navigatorKey.currentContext;
          if (messengerContext == null) return;
          ScaffoldMessenger.of(messengerContext).showSnackBar(
            const SnackBar(
              content: Text(
                "Couldn't connect to a device. Check Settings to reconfigure it.",
              ),
              duration: Duration(seconds: 6),
            ),
          );
          return;
        }
        if (state is ConnectionConnecting) {
          await showDialog<void>(
            context: navigatorKey.currentContext!,
            barrierDismissible: false,
            useRootNavigator: true,
            routeSettings: RouteSettings(name: 'connection_dialog'),
            builder: (_) => AlertDialog(title: Text('Connecting...')),
          );
        } else if (state is ConnectionPaused) {
          await showDialog<void>(
            context: navigatorKey.currentContext!,
            barrierDismissible: false,
            useRootNavigator: true,
            routeSettings: RouteSettings(name: 'connection_dialog'),
            builder: (_) => AlertDialog(title: Text('Paused')),
          );
        }
      },
      child: child,
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `fvm flutter test test/ui/home/device_connection/connection_modal_wrapper_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/ui/home/device_connection/connection_modal_wrapper.dart test/ui/home/device_connection/connection_modal_wrapper_test.dart
git commit -m "Show a dismissible banner instead of a blocking dialog on ConnectionFailed"
```

---

## Task 10: `DeviceConfigModal` and per-role wrappers

**Files:**
- Create: `lib/ui/device_selection/device_config_modal.dart`
- Create: `lib/ui/device_selection/scale_config_modal.dart`
- Create: `lib/ui/device_selection/pressure_config_modal.dart`
- Test: `test/ui/device_selection/device_config_modal_test.dart`

**Interfaces:**
- Consumes: nothing role-specific (pure widget) for `DeviceConfigModal`; `ScaleConfigModal`/`PressureConfigModal` consume `scaleDeviceOptions`/`pressureDeviceOptions` (Task 6) and `DeviceSelectionCubit` (Task 8).
- Produces:
  - `class DeviceOption { final Type type; final String displayName; }`
  - `class DeviceConfigModal extends StatefulWidget { const DeviceConfigModal({required String title, required List<DeviceOption> options, required Future<void> Function(Type) onConnect}); }`
  - `class ScaleConfigModal { static Future<void> show(BuildContext, {required BluetoothDevicesService bluetoothService, required Talker talker}); }`
  - `class PressureConfigModal { static Future<void> show(BuildContext, {required BluetoothDevicesService bluetoothService, required Talker talker}); }`
  - Consumed by Task 11 (onboarding) and Task 12 (`SettingsScreen`).

- [ ] **Step 1: Write the failing tests**

```dart
// test/ui/device_selection/device_config_modal_test.dart
import 'package:espresso_log/ui/device_selection/device_config_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _Probe {
  Type? connectedType;
  bool shouldFail = false;
  int attempts = 0;

  Future<void> onConnect(Type type) async {
    attempts++;
    connectedType = type;
    if (shouldFail) {
      throw Exception('unreachable');
    }
  }
}

void main() {
  Future<void> pumpModal(WidgetTester tester, _Probe probe) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showDialog<void>(
              context: context,
              barrierDismissible: false,
              builder: (_) => DeviceConfigModal(
                title: 'Choose a scale',
                options: const [
                  DeviceOption(type: String, displayName: 'Fake Brand'),
                  DeviceOption(type: int, displayName: 'Fake Mock'),
                ],
                onConnect: probe.onConnect,
              ),
            ),
            child: const Text('Open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }

  testWidgets('lists options and connects on tap', (tester) async {
    final probe = _Probe();
    await pumpModal(tester, probe);

    expect(find.text('Fake Brand'), findsOneWidget);
    expect(find.text('Fake Mock'), findsOneWidget);

    await tester.tap(find.text('Fake Brand'));
    await tester.pumpAndSettle();

    expect(probe.connectedType, String);
    // Dialog closes on success.
    expect(find.byType(DeviceConfigModal), findsNothing);
  });

  testWidgets('shows retry/back on failure instead of closing', (tester) async {
    final probe = _Probe()..shouldFail = true;
    await pumpModal(tester, probe);

    await tester.tap(find.text('Fake Brand'));
    await tester.pumpAndSettle();

    expect(find.byType(DeviceConfigModal), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(find.text('Back'), findsOneWidget);

    probe.shouldFail = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(probe.attempts, 2);
    expect(find.byType(DeviceConfigModal), findsNothing);
  });

  testWidgets('Back returns to the selection list without closing the modal', (
    tester,
  ) async {
    final probe = _Probe()..shouldFail = true;
    await pumpModal(tester, probe);

    await tester.tap(find.text('Fake Brand'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Back'));
    await tester.pumpAndSettle();

    expect(find.byType(DeviceConfigModal), findsOneWidget);
    expect(find.text('Fake Brand'), findsOneWidget);
    expect(find.text('Fake Mock'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `fvm flutter test test/ui/device_selection/device_config_modal_test.dart`
Expected: FAIL — file doesn't exist.

- [ ] **Step 3: Implement `DeviceConfigModal`**

```dart
// lib/ui/device_selection/device_config_modal.dart
import 'package:flutter/material.dart';

class DeviceOption {
  const DeviceOption({required this.type, required this.displayName});

  final Type type;
  final String displayName;
}

class DeviceConfigModal extends StatefulWidget {
  const DeviceConfigModal({
    super.key,
    required this.title,
    required this.options,
    required this.onConnect,
  });

  final String title;
  final List<DeviceOption> options;
  final Future<void> Function(Type selectedType) onConnect;

  @override
  State<DeviceConfigModal> createState() => _DeviceConfigModalState();
}

enum _ModalStep { selecting, connecting, failed }

class _DeviceConfigModalState extends State<DeviceConfigModal> {
  _ModalStep _step = _ModalStep.selecting;
  Type? _selectedType;

  Future<void> _connect(Type type) async {
    setState(() {
      _selectedType = type;
      _step = _ModalStep.connecting;
    });
    try {
      await widget.onConnect(type);
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) setState(() => _step = _ModalStep.failed);
    }
  }

  String _displayNameFor(Type type) => widget.options
      .firstWhere((option) => option.type == type)
      .displayName;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: switch (_step) {
        _ModalStep.selecting => Column(
          mainAxisSize: MainAxisSize.min,
          children: widget.options
              .map(
                (option) => ListTile(
                  title: Text(option.displayName),
                  onTap: () => _connect(option.type),
                ),
              )
              .toList(),
        ),
        _ModalStep.connecting => const SizedBox(
          height: 80,
          child: Center(child: CircularProgressIndicator()),
        ),
        _ModalStep.failed => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Could not connect to ${_displayNameFor(_selectedType!)}.'),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => setState(() => _step = _ModalStep.selecting),
                  child: const Text('Back'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () => _connect(_selectedType!),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ],
        ),
      },
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `fvm flutter test test/ui/device_selection/device_config_modal_test.dart`
Expected: PASS

- [ ] **Step 5: Implement the per-role wrappers (no separate test — thin composition, exercised end-to-end by Task 12)**

```dart
// lib/ui/device_selection/scale_config_modal.dart
import 'package:espresso_log/data/bluetooth/bluetooth_devices_service.dart';
import 'package:espresso_log/data/scale/scale_device_options.dart';
import 'package:espresso_log/ui/device_selection/device_config_modal.dart';
import 'package:espresso_log/ui/device_selection/device_selection_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talker_flutter/talker_flutter.dart';

class ScaleConfigModal extends StatelessWidget {
  const ScaleConfigModal({
    super.key,
    required this.bluetoothService,
    required this.talker,
  });

  final BluetoothDevicesService bluetoothService;
  final Talker talker;

  static Future<void> show(
    BuildContext context, {
    required BluetoothDevicesService bluetoothService,
    required Talker talker,
  }) {
    final cubit = context.read<DeviceSelectionCubit>();
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: ScaleConfigModal(bluetoothService: bluetoothService, talker: talker),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<DeviceSelectionCubit>();
    final options = scaleDeviceOptions.entries
        .map(
          (entry) => DeviceOption(
            type: entry.key,
            displayName: entry.value(bluetoothService, talker).displayName,
          ),
        )
        .toList();

    return DeviceConfigModal(
      title: 'Choose a scale',
      options: options,
      onConnect: (type) async {
        final repository = scaleDeviceOptions[type]!(bluetoothService, talker);
        await repository.init();
        await cubit.selectScaleType(type);
      },
    );
  }
}
```

```dart
// lib/ui/device_selection/pressure_config_modal.dart
import 'package:espresso_log/data/bluetooth/bluetooth_devices_service.dart';
import 'package:espresso_log/data/pressure/pressure_device_options.dart';
import 'package:espresso_log/ui/device_selection/device_config_modal.dart';
import 'package:espresso_log/ui/device_selection/device_selection_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talker_flutter/talker_flutter.dart';

class PressureConfigModal extends StatelessWidget {
  const PressureConfigModal({
    super.key,
    required this.bluetoothService,
    required this.talker,
  });

  final BluetoothDevicesService bluetoothService;
  final Talker talker;

  static Future<void> show(
    BuildContext context, {
    required BluetoothDevicesService bluetoothService,
    required Talker talker,
  }) {
    final cubit = context.read<DeviceSelectionCubit>();
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: PressureConfigModal(
          bluetoothService: bluetoothService,
          talker: talker,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<DeviceSelectionCubit>();
    final options = pressureDeviceOptions.entries
        .map(
          (entry) => DeviceOption(
            type: entry.key,
            displayName: entry.value(bluetoothService, talker).displayName,
          ),
        )
        .toList();

    return DeviceConfigModal(
      title: 'Choose a pressure sensor',
      options: options,
      onConnect: (type) async {
        final repository = pressureDeviceOptions[type]!(bluetoothService, talker);
        await repository.init();
        await cubit.selectPressureType(type);
      },
    );
  }
}
```

- [ ] **Step 6: Run analyzer**

```bash
fvm flutter analyze
```
Expected: no errors.

- [ ] **Step 7: Commit**

```bash
git add lib/ui/device_selection/device_config_modal.dart lib/ui/device_selection/scale_config_modal.dart lib/ui/device_selection/pressure_config_modal.dart test/ui/device_selection/device_config_modal_test.dart
git commit -m "Add shared DeviceConfigModal and per-role wrappers"
```

---

## Task 11: Wire onboarding, resume-checks, and runtime device swapping

**Files:**
- Create: `lib/device_scoped_app.dart`
- Modify: `lib/main.dart`

**Interfaces:**
- Consumes: `DeviceSelectionCubit` (Task 8), `scaleDeviceOptions`/`pressureDeviceOptions` (Task 6), `ScaleConfigModal`/`PressureConfigModal` (Task 10), `ConnectionCubit`/`ConnectionModalWrapper` (Tasks 2, 9).
- Produces: `DeviceScopedApp`, the widget that owns the per-selection repositories/rules/cubits and the app's `MaterialApp.router`.

This task is primarily composition-root wiring; it's verified by running the app rather than unit tests, matching how `main.dart`/`MyApp` have no existing test coverage today. The prior tasks' unit tests already cover the logic being wired together (selection resolution, connection failure handling, modal behavior).

- [ ] **Step 1: Create `DeviceScopedApp`**

```dart
// lib/device_scoped_app.dart
import 'dart:async';

import 'package:espresso_log/data/bluetooth/bluetooth_devices_service.dart';
import 'package:espresso_log/data/pressure/pressure_device_options.dart';
import 'package:espresso_log/data/scale/scale_device_options.dart';
import 'package:espresso_log/domain/shot/abstract_shot_clock.dart';
import 'package:espresso_log/domain/shot/auto_start_stop_rule.dart';
import 'package:espresso_log/domain/shot/auto_tare_rule.dart';
import 'package:espresso_log/domain/telemetry/pressure_repository.dart';
import 'package:espresso_log/domain/telemetry/scale_repository.dart';
import 'package:espresso_log/router.dart';
import 'package:espresso_log/ui/components/current-weight/current_weight_cubit.dart';
import 'package:espresso_log/ui/components/pressure/pressure_cubit.dart';
import 'package:espresso_log/ui/components/weight-change/weight_change_cubit.dart';
import 'package:espresso_log/ui/device_selection/device_selection_cubit.dart';
import 'package:espresso_log/ui/device_selection/pressure_config_modal.dart';
import 'package:espresso_log/ui/device_selection/scale_config_modal.dart';
import 'package:espresso_log/ui/home/device_connection/connection_cubit.dart';
import 'package:espresso_log/ui/home/device_connection/connection_modal_wrapper.dart';
import 'package:espresso_log/ui/shot/timer/timer_cubit.dart';
import 'package:espresso_log/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:idle_detector_wrapper/idle_detector_wrapper.dart';
import 'package:provider/provider.dart';
import 'package:talker_flutter/talker_flutter.dart';

/// Owns the repositories, domain rules, and cubits for the currently
/// selected scale/pressure device types. Mounted once selection is either
/// fully resolved or still being resolved through onboarding (using
/// [MockScaleService]/[MockPressureService] as an inert placeholder while
/// onboarding is incomplete, per [scaleType]/[pressureType]).
class DeviceScopedApp extends StatefulWidget {
  const DeviceScopedApp({
    super.key,
    required this.scaleType,
    required this.pressureType,
    required this.navigatorKey,
  });

  final Type scaleType;
  final Type pressureType;
  final GlobalKey<NavigatorState> navigatorKey;

  @override
  State<DeviceScopedApp> createState() => _DeviceScopedAppState();
}

class _DeviceScopedAppState extends State<DeviceScopedApp>
    with WidgetsBindingObserver {
  late final ScaleRepository _scaleRepository;
  late final PressureRepository _pressureRepository;
  late final AbstractAutoTareRule _autoTareRule;
  late final AbstractAutoStartStopRule _autoStartStopRule;
  late final ConnectionCubit _connectionCubit;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    final bluetoothService = context.read<BluetoothDevicesService>();
    final talker = context.read<Talker>();
    final shotClock = context.read<AbstractShotClock>();

    _scaleRepository = scaleDeviceOptions[widget.scaleType]!(
      bluetoothService,
      talker,
    );
    _pressureRepository = pressureDeviceOptions[widget.pressureType]!(
      bluetoothService,
      talker,
    );
    _autoTareRule = AutoTareRule(_scaleRepository);
    _autoStartStopRule = AutoStartStopRule(_pressureRepository, shotClock);
    _connectionCubit = ConnectionCubit(_scaleRepository, _pressureRepository);

    final deviceSelection = context.read<DeviceSelectionCubit>();
    if (deviceSelection.state.isResolved) {
      unawaited(_connectionCubit.connect());
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) => _runOnboarding());
    }
  }

  Future<void> _runOnboarding() async {
    final deviceSelection = context.read<DeviceSelectionCubit>();
    final bluetoothService = context.read<BluetoothDevicesService>();
    final talker = context.read<Talker>();
    final navContext = widget.navigatorKey.currentContext;
    if (navContext == null) return;

    if (deviceSelection.state.scaleType == null) {
      await ScaleConfigModal.show(
        navContext,
        bluetoothService: bluetoothService,
        talker: talker,
      );
    }
    if (deviceSelection.state.pressureType == null) {
      await PressureConfigModal.show(
        navContext,
        bluetoothService: bluetoothService,
        talker: talker,
      );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_connectionCubit.reconnect());
    }
  }

  @override
  Widget build(BuildContext context) {
    final talker = context.read<Talker>();
    final shotClock = context.read<AbstractShotClock>();
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => CurrentWeightCubit(_scaleRepository)),
        BlocProvider(create: (_) => WeightChangeCubit(_scaleRepository)),
        BlocProvider(create: (_) => TimerCubit(shotClock)),
        BlocProvider(create: (_) => PressureCubit(_pressureRepository)),
        BlocProvider.value(value: _connectionCubit),
      ],
      child: MultiProvider(
        providers: [
          Provider<ScaleRepository>.value(value: _scaleRepository),
          Provider<PressureRepository>.value(value: _pressureRepository),
          Provider<AbstractAutoTareRule>.value(value: _autoTareRule),
          Provider<AbstractAutoStartStopRule>.value(value: _autoStartStopRule),
        ],
        child: IdleDetector(
          idleTime: const Duration(minutes: 5),
          onIdle: () {
            unawaited(_connectionCubit.disconnect());
          },
          onActive: () {
            unawaited(_connectionCubit.reconnect());
          },
          child: ConnectionModalWrapper(
            navigatorKey: widget.navigatorKey,
            child: MaterialApp.router(
              theme: buildAppTheme(),
              routerConfig: AppRouter(talker, widget.navigatorKey).router,
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Rewrite `main.dart`**

```dart
// lib/main.dart
import 'package:espresso_log/data/bluetooth/bluetooth_devices_service.dart';
import 'package:espresso_log/data/device_selection/device_selection_service.dart';
import 'package:espresso_log/data/scale/mock_scale_service.dart';
import 'package:espresso_log/data/pressure/mock_pressure_service.dart';
import 'package:espresso_log/device_scoped_app.dart';
import 'package:espresso_log/domain/shot/abstract_shot_clock.dart';
import 'package:espresso_log/domain/shot/shot_clock.dart';
import 'package:espresso_log/ui/device_selection/device_selection_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:talker_flutter/talker_flutter.dart';

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

  final deviceSelectionCubit = DeviceSelectionCubit(
    DeviceSelectionService(),
    useMockScale: useMockScale,
    useMockPressure: useMockPressure,
  );
  await deviceSelectionCubit.load();

  runApp(
    MultiProvider(
      providers: [
        Provider<Talker>.value(value: talker),
        Provider<BluetoothDevicesService>.value(value: bluetoothService),
        Provider<AbstractShotClock>.value(value: shotClock),
      ],
      child: BlocProvider.value(
        value: deviceSelectionCubit,
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DeviceSelectionCubit, DeviceSelectionState>(
      builder: (context, selection) {
        final key = ValueKey(
          selection.isResolved
              ? '${selection.scaleType}-${selection.pressureType}'
              : 'unconfigured',
        );
        return DeviceScopedApp(
          key: key,
          scaleType: selection.scaleType ?? MockScaleService,
          pressureType: selection.pressureType ?? MockPressureService,
          navigatorKey: globalNavigatorKey,
        );
      },
    );
  }
}
```

Note the `ValueKey` uses a stable `'unconfigured'` value for the entire duration selection is unresolved (regardless of partial onboarding progress on one role), so the in-progress onboarding dialog's `Navigator` isn't torn down between the scale step and the pressure step. Only once both roles resolve does the key change to the real pair, remounting `DeviceScopedApp` with the actual chosen repositories.

- [ ] **Step 3: Manual verification**

```bash
fvm flutter run --dart-define USE_MOCK_SCALE=true --dart-define USE_MOCK_PRESSURE=true
```
Confirm: app boots straight to Home with no onboarding shown (both roles auto-selected as mock).

```bash
fvm flutter run
```
On a device/simulator with no prior selection persisted, confirm: the scale picker modal appears first, then (after connecting or picking mock) the pressure picker modal appears, then the app proceeds to Home. Force-quit and relaunch: confirm onboarding does not reappear (selection was persisted).

- [ ] **Step 4: Run full test suite and analyzer**

```bash
fvm flutter analyze
fvm flutter test
```
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/device_scoped_app.dart lib/main.dart
git commit -m "Wire onboarding, resume reconnect, and runtime device swapping into MyApp"
```

---

## Task 12: Settings screen — device rows and removal of debug buttons

**Files:**
- Modify: `lib/ui/settings/settings.dart`
- Test: `test/ui/settings/settings_test.dart`

**Interfaces:**
- Consumes: `DeviceSelectionCubit` (Task 8), `scaleDeviceOptions`/`pressureDeviceOptions` (Task 6), `ScaleConfigModal`/`PressureConfigModal` (Task 10).

- [ ] **Step 1: Write the failing test**

```dart
// test/ui/settings/settings_test.dart
import 'package:espresso_log/data/bluetooth/bluetooth_devices_service.dart';
import 'package:espresso_log/data/scale/decent_scale_service.dart';
import 'package:espresso_log/data/pressure/bookoo_pressure_service.dart';
import 'package:espresso_log/data/device_selection/device_selection_service.dart';
import 'package:espresso_log/ui/device_selection/device_config_modal.dart';
import 'package:espresso_log/ui/device_selection/device_selection_cubit.dart';
import 'package:espresso_log/ui/settings/settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:provider/provider.dart';
import 'package:talker_flutter/talker_flutter.dart';

@GenerateNiceMocks([
  MockSpec<BluetoothDevicesService>(),
  MockSpec<Talker>(),
  MockSpec<DeviceSelectionService>(),
])
import 'settings_test.mocks.dart';

void main() {
  Future<void> pumpSettings(WidgetTester tester) async {
    final cubit = DeviceSelectionCubit(
      MockDeviceSelectionService(),
      useMockScale: false,
      useMockPressure: false,
    )..emit(
      const DeviceSelectionState(
        scaleType: DecentScaleService,
        pressureType: BookooPressureService,
      ),
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<BluetoothDevicesService>.value(
            value: MockBluetoothDevicesService(),
          ),
          Provider<Talker>.value(value: MockTalker()),
        ],
        child: BlocProvider<DeviceSelectionCubit>.value(
          value: cubit,
          child: const MaterialApp(home: SettingsScreen()),
        ),
      ),
    );
  }

  testWidgets('shows the current scale and pressure selection', (tester) async {
    await pumpSettings(tester);

    expect(find.text('Decent Scale'), findsOneWidget);
    expect(find.text('Bookoo Pressure Sensor'), findsOneWidget);
    expect(find.text('init'), findsNothing);
    expect(find.text('tare'), findsNothing);
  });

  testWidgets('tapping "Change device" for the scale opens the scale modal', (
    tester,
  ) async {
    await pumpSettings(tester);

    await tester.tap(find.widgetWithText(FilledButton, 'Change device').first);
    await tester.pumpAndSettle();

    expect(find.byType(DeviceConfigModal), findsOneWidget);
    expect(find.text('Choose a scale'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `fvm flutter test test/ui/settings/settings_test.dart`
Expected: FAIL — `SettingsScreen` doesn't expose device rows yet, and `DeviceSelectionCubit.emit` is protected (test needs `emit` accessible — see Step 3 note).

Since `Cubit.emit` is `protected` in `flutter_bloc`, the test above seeds state via a small test-only subclass instead. Replace the `cubit` construction in the test with:

```dart
class _SeededDeviceSelectionCubit extends DeviceSelectionCubit {
  _SeededDeviceSelectionCubit(super.service, DeviceSelectionState seed)
    : super(useMockScale: false, useMockPressure: false) {
    emit(seed);
  }
}
```

and construct it as:

```dart
    final cubit = _SeededDeviceSelectionCubit(
      MockDeviceSelectionService(),
      const DeviceSelectionState(
        scaleType: DecentScaleService,
        pressureType: BookooPressureService,
      ),
    );
```

(`emit` is accessible from a subclass in the same package since `protected` in `package:meta` only warns outside the defining library's package — this test lives in the same `espresso_log` package.)

- [ ] **Step 3: Rewrite `SettingsScreen`**

```dart
// lib/ui/settings/settings.dart
import 'package:espresso_log/data/bluetooth/bluetooth_devices_service.dart';
import 'package:espresso_log/data/pressure/pressure_device_options.dart';
import 'package:espresso_log/data/scale/scale_device_options.dart';
import 'package:espresso_log/ui/device_selection/device_selection_cubit.dart';
import 'package:espresso_log/ui/device_selection/pressure_config_modal.dart';
import 'package:espresso_log/ui/device_selection/scale_config_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:talker_flutter/talker_flutter.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  String _scaleDisplayName(
    Type? type,
    BluetoothDevicesService bluetoothService,
    Talker talker,
  ) {
    if (type == null) return 'Not configured';
    return scaleDeviceOptions[type]!(bluetoothService, talker).displayName;
  }

  String _pressureDisplayName(
    Type? type,
    BluetoothDevicesService bluetoothService,
    Talker talker,
  ) {
    if (type == null) return 'Not configured';
    return pressureDeviceOptions[type]!(bluetoothService, talker).displayName;
  }

  @override
  Widget build(BuildContext context) {
    final bluetoothService = context.read<BluetoothDevicesService>();
    final talker = context.read<Talker>();
    final selection = context.watch<DeviceSelectionCubit>().state;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        ListTile(
          title: const Text('Scale'),
          subtitle: Text(
            _scaleDisplayName(selection.scaleType, bluetoothService, talker),
          ),
          trailing: FilledButton(
            onPressed: () => ScaleConfigModal.show(
              context,
              bluetoothService: bluetoothService,
              talker: talker,
            ),
            child: const Text('Change device'),
          ),
        ),
        ListTile(
          title: const Text('Pressure sensor'),
          subtitle: Text(
            _pressureDisplayName(
              selection.pressureType,
              bluetoothService,
              talker,
            ),
          ),
          trailing: FilledButton(
            onPressed: () => PressureConfigModal.show(
              context,
              bluetoothService: bluetoothService,
              talker: talker,
            ),
            child: const Text('Change device'),
          ),
        ),
        FilledButton(
          onPressed: () => context.push('/settings/log'),
          child: const Text("Logs"),
        ),
        FilledButton(
          onPressed: () => context.push('/settings/recorder'),
          child: const Text("Recorder"),
        ),
      ],
    );
  }
}
```

- [ ] **Step 4: Regenerate mocks and run tests**

```bash
fvm dart run build_runner build --delete-conflicting-outputs
fvm flutter test test/ui/settings/settings_test.dart
```
Expected: PASS

- [ ] **Step 5: Run full test suite and analyzer**

```bash
fvm flutter analyze
fvm flutter test
```
Expected: PASS everywhere.

- [ ] **Step 6: Commit**

```bash
git add lib/ui/settings/settings.dart test/ui/settings/settings_test.dart test/ui/settings/settings_test.mocks.dart
git commit -m "Show current device selection in Settings and let the user change it"
```

---

## Final check

- [ ] Run `fvm flutter analyze` and `fvm flutter test` once more from a clean state to confirm the whole branch is green.
- [ ] Manually run through the three flows described in the spec: first-launch onboarding (real hardware or mock), forced-resume reconnect (background/foreground the app), and Settings-triggered device change (confirms the app lands back on Home per the accepted navigation-reset trade-off).
