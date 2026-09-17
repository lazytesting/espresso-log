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
- Run a single test file: `fvm flutter test test/domain/shot/auto_tare_rule_test.dart`
- Regenerate mocks after changing an interface annotated with `@GenerateNiceMocks` (e.g.
  `ScaleRepository`): `fvm dart run build_runner build --delete-conflicting-outputs`

## Architecture

### Domain layer: hardware-agnostic types, ports, and shot logic

`lib/domain/` holds all business types and logic, with no dependency on `flutter_blue_plus` or any
other BLE package — this is what Tasks 1–12 of the domain-layer-refactor plan built to replace the
old `lib/devices/`/`lib/services/` split.

- `lib/domain/telemetry/` — the raw sensor data model and its driven ports. `WeightReading` and
  `TareEvent` (`scale_event.dart`, `weight_reading.dart`, `tare_event.dart`) both implement the
  shared `ScaleEvent` type; `PressureReading` (`pressure_reading.dart`) is the pressure sensor's
  reading. `ScaleRepository` / `PressureRepository` (`scale_repository.dart`,
  `pressure_repository.dart`) are the abstract interfaces — each exposing a single
  `Stream<ScaleEvent>` / `Stream<PressureReading>` plus device commands like `tareCommand()` — that
  the data layer implements and everything downstream depends on.
- `lib/domain/shot/` — shot-timing and shot-recording logic. `TimerEvent` and its subtypes
  (`TimerStarted`, `TimerTicked`, `TimerStopped` in `timer_event.dart`) are emitted by
  `AbstractShotClock`/`ShotClock` (`abstract_shot_clock.dart`, `shot_clock.dart`), an internal
  timer abstraction (not a driven port — it has no real/mock split, just a test-substitutable
  interface). `AbstractAutoTareRule`/`AutoTareRule` (`auto_tare_rule.dart`) watches the scale
  stream for a weight that jumps and then holds stable for >1s and calls `tareCommand()` — this is
  how the scale auto-tares when a cup is placed. `AbstractAutoStartStopRule`/`AutoStartStopRule`
  (`auto_start_stop_rule.dart`) watches the pressure stream against two thresholds and
  starts/stops the shot clock — this is how the shot timer auto-starts/stops without user input.
  Both rules are enabled/disabled (not just fire-and-forget) so they can be paused between shots.
  `ShotRecordingSession` (`shot_recording_session.dart`, with `ShotSnapshot`/`ShotGraphPoint` in
  `shot_snapshot.dart`/`shot_graph_point.dart`) is a synchronous accumulator: it owns the
  tare-zeroing/weight-pressure buffering math relative to the shot's start time (zeroing weight
  before the tare timestamp so pre-tare cup weight doesn't pollute the graph) — logic that used to
  live untested inline in `ShotGraphCubit`.

### Data layer: adapters implementing the domain's repository interfaces

`lib/data/` contains the concrete, hardware-facing implementations of the telemetry ports:
- `DecentScaleService` (`lib/data/scale/decent_scale_service.dart`) / `BookooPressureService`
  (`lib/data/pressure/bookoo_pressure_service.dart`) — real BLE devices implementing
  `ScaleRepository`/`PressureRepository`, built on `BluetoothDevicesService`
  (`lib/data/bluetooth/bluetooth_devices_service.dart`), which handles scanning, connecting, and
  remembering a paired device's ID in `SharedPreferences` so reconnects skip the scan.
  `BookooPressureService` also mixes in `BatteryDeviceMixin`
  (`lib/data/models/battery_device_mixin.dart`) for shared battery-level parsing.
- `MockScaleService` (`lib/data/scale/mock_scale_service.dart`) / `MockPressureService`
  (`lib/data/pressure/mock_pressure_service.dart`) — synthetic data generators implementing the
  same interfaces, used when the `USE_MOCK_SCALE`/`USE_MOCK_PRESSURE` dart-defines are set.

Everything downstream (cubits) depends on the domain's abstract interfaces, never these concrete
implementations — `lib/main.dart` is the only place that decides real vs. mock and wires concrete
instances in via `BlocProvider`/`Provider`.

**Naming conventions** across `lib/domain/` and `lib/data/`: `*Repository` names a driven port to
external hardware (`ScaleRepository`, `PressureRepository`); `Abstract*` names an internal
interface that exists for test-substitutability but has no external system behind it
(`AbstractShotClock`, `AbstractAutoTareRule`, `AbstractAutoStartStopRule`); `*Rule` names a
reactive domain class that watches a stream and drives side effects (`AutoTareRule`,
`AutoStartStopRule`); `*Session` names a synchronous accumulator (`ShotRecordingSession`);
`*Service` is unchanged and still names the data-layer adapters (`DecentScaleService`,
`BookooPressureService`, `MockScaleService`, `MockPressureService`, `BluetoothDevicesService`).

### UI layer: one Cubit per widget/concern, subscribing to domain streams

`lib/ui/` follows a `flutter_bloc` Cubit-per-feature pattern; each feature folder has a
`*_cubit.dart`, `*_state.dart` (as a `part of` the cubit file), and `*_widget.dart`. Cubits now
depend only on domain types (`ScaleRepository`, `PressureRepository`, `AbstractShotClock`,
`AbstractAutoTareRule`, `AbstractAutoStartStopRule`) — never the concrete `lib/data/`
implementations — and `listen()` to their streams, filtering by event type (`is`/pattern matching
on `ScaleEvent`/`TimerEvent` subtypes) and emitting UI state.

`ShotGraphCubit` (`lib/ui/shot/shot_graph/shot_graph_cubit.dart`) is the central orchestrator for
an active shot, but is now a thin one: it composes `AbstractAutoStartStopRule`,
`AbstractAutoTareRule`, the scale/pressure repositories, and `AbstractShotClock`, and delegates
all the accumulation/zeroing math to a `ShotRecordingSession` it owns — calling `session.start()`,
`session.tare()`, `session.addWeight()`/`addPressure()`, and reading `session.snapshot` — emitting
`ShotGraphWaiting` → `ShotGraphUpdating` → `ShotGraphStopped` states consumed by the shot graph
widget.

All top-level repositories, rules, and cubits are constructed once in `main()` and provided
app-wide via `MultiBlocProvider`/`MultiProvider`, rather than being scoped to a route.

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
