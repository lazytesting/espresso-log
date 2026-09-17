# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

`espresso_log` is a Flutter app that reads live shot metrics (weight, pressure, timer) from BLE
devices while pulling an espresso shot — a Decent Espresso Scale and a Bookoo Pressure Sensor are
currently supported. The app is explicitly meant to add zero steps to the espresso workflow: scale
taring and shot timing are automated from sensor data rather than by the user pressing buttons. It
is early WiP; there's no persistence of shot history yet (see README.md future plans).

## Commands

This project uses [FVM](https://fvm.app/) to pin the Flutter SDK (version in `.fvmrc`, currently
3.35.7). Prefix Flutter/Dart commands with `fvm` as shown below.

- Install dependencies: `fvm flutter pub get`
- One-time setup of the pre-commit hook: `fvm dart run tools/setup_git_hooks.dart` (writes
  `.git/hooks/pre-commit` to run `dart_pre_commit`; use `--no-fvm` to generate a hook that calls
  `dart` directly instead of `fvm dart`)
- Run the app: `fvm flutter run`
- Run the app against mock devices (no real BLE hardware needed) instead of connecting to real
  Bluetooth devices:
  - `fvm flutter run --dart-define USE_MOCK_SCALE=true`
  - `fvm flutter run --dart-define USE_MOCK_PRESSURE=true`
  - both together, matching the "espresso_log mock all" VS Code launch config, is the easiest way
    to iterate on UI/graph logic without hardware
- Static analysis / lint: `fvm flutter analyze`
- Run all tests: `fvm flutter test`
- Run a single test file: `fvm flutter test test/services/auto_tare_service_test.dart`
- Regenerate mocks after changing an interface annotated with `@GenerateNiceMocks` (e.g.
  `AbstractScaleService`): `fvm dart run build_runner build --delete-conflicting-outputs`

## Architecture

### Device layer: abstract service + real/mock implementation, all Stream-driven

Under `lib/devices/`, each physical concern (scale, pressure sensor, timer) is modeled as an
abstract service exposing a single `Stream<Notification>` plus lifecycle methods (`init`,
device-specific commands like `tareCommand`), for example
`lib/devices/scale/models/abstract_scale_service.dart`. Concrete implementations:
- `DecentScaleService` / `BookooPressureService` — real BLE devices, built on
  `BluetoothDevicesService` (`lib/devices/bluetooth/bluetooth_service.dart`), which handles
  scanning, connecting, and remembering a paired device's ID in `SharedPreferences` so
  reconnects skip the scan.
- `MockScaleService` / `MockPressureService` — synthetic data generators used when the
  `USE_MOCK_SCALE`/`USE_MOCK_PRESSURE` dart-defines are set.

Everything downstream (services, cubits) depends on the abstract interfaces, never the concrete
BLE implementations — `lib/main.dart` is the only place that decides real vs. mock and wires
concrete instances in via `BlocProvider`/`Provider`.

`Notification` (`lib/devices/models/notification.dart`) is the shared base type flowing through
every device stream; concrete types (`WeightNotification`, `TareNotification`,
`PressureNotification`, `TimerStartedNotification`, `TimerStoppedNotification`, ...) are matched
with `is`/`cast<T>()` by listeners downstream (see `AutoTareService`, `ShotGraphCubit`).

### Domain services orchestrate device streams into behavior

`lib/services/` contains logic that reacts to one device's stream to drive another device,
implementing the "don't get in the way" automation from the README:
- `AutoTareService` watches the scale stream for a weight that jumps and then holds stable for
  >1s, and calls `tareCommand()` on the scale — this is how the scale auto-tares when a cup is
  placed.
- `AutoStartStopService` watches the pressure stream against two thresholds and starts/stops the
  `TimerService` — this is how the shot timer auto-starts/stops without user input.

Both are enabled/disabled (not just fire-and-forget) so they can be paused between shots.

### UI layer: one Cubit per widget/concern, subscribing to device or domain streams

`lib/ui/` follows a `flutter_bloc` Cubit-per-feature pattern; each feature folder has a
`*_cubit.dart`, `*_state.dart` (as a `part of` the cubit file), and `*_widget.dart`. Cubits
generally take an abstract device/domain service in their constructor and `listen()` to its
stream, filtering by notification type and emitting UI state.

`ShotGraphCubit` (`lib/ui/shot/shot_graph/shot_graph_cubit.dart`) is the central orchestrator for
an active shot: it composes `AutoStartStopService`, `AutoTareService`, the scale/pressure/timer
services, buffers weight/pressure notifications relative to `_startDateTime` (zeroing weight
before the tare timestamp so pre-tare cup weight doesn't pollute the graph), and emits
`ShotGraphWaiting` → `ShotGraphUpdating` → `ShotGraphStopped` states consumed by the shot graph
widget.

All top-level services and cubits are constructed once in `main()` and provided app-wide via
`MultiBlocProvider`/`MultiProvider`, rather than being scoped to a route.

### Navigation

`lib/router.dart` defines a `go_router` config with a bottom-tab `StatefulShellRoute` (Home /
History / Settings, each with its own navigator so tab state survives switching) plus a
full-screen `/shot` route pushed on top of the shell for the active-shot view. `Talker`
(`talker_flutter`) is wired in as a route observer and also powers the in-app log viewer at
`/settings/log`.

## Testing conventions

Tests use `flutter_test` + `mockito` + `bloc_test` + `rxdart`'s `BehaviorSubject` to simulate
device streams. Mocks for an abstract service are generated per-test-file via
`@GenerateNiceMocks([MockSpec<...>()])` with a matching `part`-style `import '<file>.mocks.dart'`
(build_runner output, checked into `test/`); regenerate with the `build_runner` command above
when an interface changes. Async stream-driven assertions use `await untilCalled(...)` /
`verify(...).called(n)` for expected calls and `await pumpEventQueue()` + `verifyNever(...)` for
calls that must *not* happen.
