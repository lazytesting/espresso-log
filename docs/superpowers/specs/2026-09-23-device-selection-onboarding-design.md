# Device Selection & Onboarding — Spec

**Date:** 2026-09-23
**Status:** Agreed with user, ready to implement

## Goal

Make scale/pressure device selection a user-facing, runtime choice instead of
a compile-time `--dart-define` flag. On first launch the user picks which
scale and pressure sensor to use (from currently-supported brands, or mock)
and pairs it; on every subsequent startup/resume the app verifies the
selected devices are connected and reconnects if needed; the user can change
the selection later from Settings without restarting the app. Settings must
stay fully usable regardless of connection state.

Scope is limited to the two roles and brands that exist today (scale: Decent
or mock; pressure: Bookoo or mock) — no new hardware support, no
multi-device-per-role support.

## Current state (for context)

- `main.dart:33-63` picks real-vs-mock per role via `bool.fromEnvironment`
  dart-defines, decided at build time. Decent is the only real scale impl,
  Bookoo the only real pressure impl — chosen with inline ternaries.
- Repositories are constructed once in `main()` and injected as fixed
  `Provider.value`/`BlocProvider` singletons (`main.dart:70-94`). Nothing
  downstream supports replacing the concrete instance after construction.
- `BluetoothDevicesService.connectToDevice(searchName)` reads a previously
  stored device ID from `SharedPreferences` keyed by device name, but nothing
  in the codebase currently *writes* that key — pairing persistence is
  incomplete today.
- `BatteryDeviceMixin` (`reconnect()`/`disconnect()`) is implemented only by
  `BookooPressureService`; `DecentScaleService` does not implement it, so
  scale reconnect is a no-op today.
- `ConnectionCubit` exposes `connect()`/`reconnect()`/`disconnect()` and a
  sealed `ConnectionState` (`ConnectionInitial`/`Connecting`/`Established`/
  `Paused`), consumed today only by `ConnectionModalWrapper`'s blocking
  dialog and by `IdleDetector`'s `onIdle`/`onActive` callbacks
  (`main.dart:103-110`). There is no `AppLifecycleState`/
  `WidgetsBindingObserver` hook anywhere in the app yet.
- `lib/router.dart` has no onboarding/first-run route; the app always boots
  into Home. `lib/ui/settings/settings.dart` has no device-selection UI —
  only debug "init"/"tare" buttons acting directly on `ScaleRepository`.

## Domain model additions

`lib/domain/telemetry/`:

- `ScaleRepository`/`PressureRepository` each gain a `String get displayName;`
  getter, implemented by every concrete class (`DecentScaleService` →
  `"Decent Scale"`, `MockScaleService` → `"Mock Scale"`,
  `BookooPressureService` → `"Bookoo Pressure Sensor"`,
  `MockPressureService` → `"Mock Pressure Sensor"`). This is metadata about
  the implementation, not vendor business logic, so it's an acceptable
  addition to the otherwise vendor-agnostic domain interfaces — it avoids
  needing a separate brand-naming enum or lookup table anywhere.
- `BluetoothDeviceMixin` — replaces `BatteryDeviceMixin`. Generalized because
  the shared connect/reconnect/disconnect/status-stream behavior applies to
  any BLE device, not just battery-powered ones. Declares `connect()`,
  `reconnect()`, `disconnect()`, a `Stream<DeviceConnectionStatus>`
  (`connecting`/`connected`/`disconnected`/`failed`), and
  `bool get isBatteryPowered` — preserving the existing idle-disconnect
  behavior, which must only apply to battery-powered devices, not to every
  BLE device generically. `BookooPressureService` implements the mixin with
  `isBatteryPowered => true` (unchanged from today). `DecentScaleService`
  adopts the mixin too (closing today's gap — scale reconnect currently
  no-ops, needed for the startup/resume check in this feature) but with
  `isBatteryPowered => false`: the scale is USB-powered in current usage, so
  it must keep opting out of idle-disconnect exactly as it does today. Mock
  services implement the mixin trivially, always reporting `connected`, with
  `isBatteryPowered => false`.
  `ConnectionCubit`'s idle-disconnect logic changes from
  `if (repo is BatteryDeviceMixin)` to
  `if (repo is BluetoothDeviceMixin && repo.isBatteryPowered)`.

No enum of device types/brands is introduced anywhere — selection is
expressed directly in terms of the concrete service classes (see below),
keeping brand knowledge entirely in `lib/data/` and out of the domain layer.

## Device registries, persistence, and runtime swapping

- `lib/data/scale/scale_device_options.dart` (and the pressure equivalent):
  a `Map<Type, ScaleRepository Function(BluetoothDevicesService, Talker)>`
  registering every constructible option for that role, e.g.
  `{DecentScaleService: (bt, talker) => DecentScaleService(bt, talker),
  MockScaleService: (bt, talker) => MockScaleService()}`. This map is both
  the source of truth for "what can be picked" (its keys) and the
  replacement for today's inline ternaries at `main.dart:57-63`. Adding a
  future brand means adding one entry here — nothing else changes. Since
  construction performs no I/O (only `.init()`/`connectToDevice` do), a
  picker can instantiate each registered option once just to read its
  `displayName` without side effects.
- `lib/data/device_selection/device_selection_service.dart` — wraps
  `SharedPreferences` (this is exactly the kind of infrastructure access
  that belongs in `lib/data/`, alongside `BluetoothDevicesService`, not in
  domain). Two responsibilities per role: persisting/reading the selected
  `Type` (serialized as its class name string) and the currently-missing
  write path for the paired device ID (`BluetoothDevicesService` today only
  reads it, never writes it).
- `DeviceSelectionCubit` (`lib/ui/`) — a single combined cubit covering both
  roles (not two separate cubits), since `MyApp`'s rebuild key needs both
  the current scale type and pressure type together. Constructed once in
  `main()`, above everything else, alongside `bluetoothService`/`talker`/
  `globalNavigatorKey`. It owns *only* "which `Type` is currently selected
  per role," backed by `DeviceSelectionService` — it does not own the
  repository instances themselves, so it survives the rebuild described
  next. It depends directly on the `lib/data/` registries and
  `DeviceSelectionService` rather than through a domain port: device
  selection isn't a hardware boundary needing mock-hardware substitutability
  the way `ScaleRepository` is, it's local persisted configuration, so this
  is a deliberate, narrow exception to "cubits depend only on domain types."
- The body of `main()`'s `runApp(...)` — currently building
  `scaleRepository`/`pressureRepository`/`autoTareRule`/`autoStartStopRule`
  and the `MultiBlocProvider`/`MultiProvider` tree (`main.dart:65-94`) — moves
  into `MyApp.build()`. `MyApp` wraps that subtree in a widget keyed by
  `Key('$selectedScaleType-$selectedPressureType')` (the `Type`s' string
  names), fed by `DeviceSelectionCubit` via `BlocBuilder`. When the selection
  changes, the key changes, and Flutter tears down the old subtree (old
  repositories, old cubits, old stream subscriptions) and rebuilds a fresh
  one via `scaleDeviceOptions[selectedType]!(bluetoothService, talker)`. No
  manual `setRepository()`/swap method needed on any consumer cubit.
- Accepted trade-off: `MaterialApp.router`/`go_router` lives inside the
  rebuilt subtree, so changing device selection resets navigation to
  `initialLocation: '/'` (Home). This only happens from a deliberate
  selection change, so landing on Home is acceptable and expected.

## Shared device-configuration modal

- `DeviceConfigModal` — one widget, parameterized by role (scale or
  pressure), used identically by onboarding and by Settings. Contents: a
  selection list built from that role's registry (`displayName` per entry),
  a "Connect" action that scans via `BluetoothDevicesService` / the chosen
  concrete service, a scanning/connecting progress state, and retry/cancel
  on scan timeout. On successful connect it writes the selection + paired
  device ID through `DeviceSelectionCubit`/`DeviceSelectionService` and
  closes. It depends only on `DeviceSelectionCubit` and the bluetooth
  scanning primitives — it has no awareness of whether it was opened from
  onboarding or Settings.
- Scan timeout behavior: show retry/cancel; the modal cannot be dismissed
  into a "resolved" state until the role has a real connected device or an
  explicitly selected mock — no silent skip.

## Onboarding

- Mocked roles (`USE_MOCK_SCALE`/`USE_MOCK_PRESSURE` dart-defines) are
  auto-selected and never shown in onboarding — this preserves today's
  `flutter run --dart-define USE_MOCK_SCALE=true` workflow for UI iteration
  without hardware.
- For non-mocked roles, on first build `MyApp` checks
  `DeviceSelectionCubit` for a persisted selection. If either real role is
  unresolved, `DeviceConfigModal` is shown for that role (via
  `globalNavigatorKey`, as a full-screen dialog/route) before the user can
  reach Home. No new `go_router` route is added — onboarding is presented
  orthogonally to the router, keeping the shell/router untouched.

## Startup / resume connection check

- `MyApp` becomes a `StatefulWidget` with `WidgetsBindingObserver` (new —
  no lifecycle observer exists in the app today), reacting to
  `AppLifecycleState.resumed` in addition to the existing idle-detector
  `onActive` path. Both call `ConnectionCubit.reconnect()`, now meaningful
  for both roles once `DecentScaleService` implements
  `BluetoothDeviceMixin`.
- On startup (after onboarding is resolved, i.e. both roles have a
  selection) and on resume, `ConnectionCubit` attempts to connect/reconnect
  using the stored device ID for each selected real device. Failure emits a
  per-role connection-failed state rather than throwing.
- Failures surface as a **non-blocking, dismissible banner** (e.g. on Home),
  not the existing blocking `ConnectionModalWrapper` dialog. The existing
  transient `Connecting…`/`Paused` dialog states are unchanged; only the
  terminal failure case changes from blocking-dialog to dismissible-banner.
  Settings remains reachable at all times — nothing today gates bottom-nav
  tab navigation on connection state, and this feature does not introduce
  such a gate.

## Settings screen changes

- `lib/ui/settings/settings.dart` gains one row per role (scale, pressure)
  showing the current selection's `displayName` and live connection status,
  each with a "Change device" button opening `DeviceConfigModal` for that
  role, pre-populated with the current selection. Saving triggers
  `DeviceSelectionCubit` to emit the new type, which rebuilds `MyApp`'s
  keyed subtree as described above, landing the user on Home.
- The existing debug "init"/"tare" buttons (`settings.dart:25-32`) are
  removed — `DeviceConfigModal` supersedes "init" for scale pairing, and
  tare remains reachable through its normal in-shot path, not Settings.

## Testing

- Data: `DeviceSelectionService` persistence round-trip (selected `Type` +
  paired device ID); `scaleDeviceOptions`/`pressureDeviceOptions` registry
  construction (each entry constructs without side effects and reports the
  expected `displayName`); `BluetoothDeviceMixin` conformance test for
  `DecentScaleService` (mirroring the existing `BookooPressureService`
  coverage), including `isBatteryPowered => false` for the scale vs. `=>
  true` for the pressure sensor.
- Cubit: `DeviceSelectionCubit` bloc_test coverage (select → persist →
  emit); `ConnectionCubit` reconnect-failure-emits-error-state coverage for
  *both* roles now that Decent supports reconnect; a regression test
  confirming idle-disconnect still only fires for `isBatteryPowered` devices
  (i.e. the scale is never idle-disconnected).
- Widget: `DeviceConfigModal` — scan/connect/retry/timeout states, and a
  smoke test confirming it behaves identically opened standalone
  (onboarding) vs. from Settings.
- No new `go_router` tests are needed since onboarding is not a route.

## Explicitly out of scope

- Support for additional scale/pressure brands beyond Decent/Bookoo/mock.
- Persisting shot history (unrelated, tracked separately per README).
- Any change to `ShotGraphCubit`'s internal accumulation logic.
