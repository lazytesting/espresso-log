# Domain Layer Refactor — Spec

**Date:** 2026-09-17
**Status:** Agreed with user, ready to implement

## Goal

Move `espresso_log` from its current pragmatic layering to an MVVM-flavored
architecture with an explicit, framework-free domain layer, using
Ports-and-Adapters (the user's preferred term for a port is "Repository").
No behavior change except where explicitly noted below.

## Layers

| Layer | Folder | Responsibility | May depend on |
|---|---|---|---|
| Domain | `lib/domain/` | Business rules, value objects, repository interfaces | nothing (plain Dart only) |
| Data | `lib/data/` | Adapters implementing domain repository interfaces against real infra (BLE, SharedPreferences) | Domain |
| Presentation (ViewModel) | `lib/ui/**/*_cubit.dart` | Subscribe to repository streams, drive domain rules, map results to UI state | Domain |
| View | `lib/ui/**/*_widget.dart`, screens | Render state, forward user input | Presentation |

Domain never imports `flutter_blue_plus`, `shared_preferences`, `flutter_bloc`,
or `syncfusion_flutter_charts`.

## Bounded contexts and their domain model

### Telemetry (`lib/domain/telemetry/`)
- `ScaleEvent` — abstract marker (`timeStamp`, `toJson()`) for the scale's
  event union. **New** — replaces the app-wide `Notification` base class,
  scoped to just the scale context where a stream genuinely carries a union
  of event types.
- `WeightReading(weight, timeStamp)` — replaces `WeightNotification`.
- `TareEvent(timeStamp)` — replaces `TareNotification`. Implements `ScaleEvent`.
- `PressureReading(pressure, timeStamp)` — replaces `PressureNotification`.
  No shared base needed: `PressureRepository.stream` is concretely typed, so
  `toJson()` resolves without a marker interface.
- `ScaleRepository` — replaces `AbstractScaleService`. `Stream<ScaleEvent> stream`,
  `init()`, `tareCommand()` (kept this name — renaming to `tare()` was
  considered and rejected to avoid unnecessary call-site churn).
- `PressureRepository` — replaces `AbstractPressureService`. `Stream<PressureReading> stream`,
  `init()`, `dispose()`.

### Shot (`lib/domain/shot/`)
- `TimerEvent` (abstract: `timeStamp`, `milliSeconds`, `toJson()`) with
  `TimerStarted`/`TimerTicked`/`TimerStopped` — replaces `TimerNotification`
  and its three subclasses (`Notification` suffix dropped).
- `AbstractShotClock` — replaces `AbstractTimerService`. Not a `Repository`:
  it fronts no external system, it's a substitutability seam for tests, so it
  keeps the existing `Abstract*` naming convention instead.
- `ShotClock` — replaces `TimerService`. **Reclassified from device/infra to
  domain**: it's a `Timer.periodic` stopwatch with zero hardware dependency,
  so it was misfiled under `devices/` today.
- `AbstractAutoTareRule` / `AutoTareRule` — replaces `AbstractAutoTareService` /
  `AutoTareService`. Logic unchanged.
- `AbstractAutoStartStopRule` / `AutoStartStopRule` — replaces
  `AbstractAutoStartStopService` / `AutoStartStopService`. Logic unchanged.
- `ShotGraphPoint(millisecond, value)` — replaces `ShotGraphData`.
- `ShotSnapshot(weightData, pressureData)` — **new**, the output of a session.
- `ShotRecordingSession` — **new**. Extracted from
  [`ShotGraphCubit._emitEvent`](../../../lib/ui/shot/shot_graph/shot_graph_cubit.dart#L83-L110)
  and its surrounding start/stop/reset handling. Pure synchronous accumulator:
  `start(DateTime)`, `stop()`, `reset()`, `tare(DateTime)`, `addWeight(WeightReading)`,
  `addPressure(PressureReading)`, `isStarted` getter, `snapshot` getter. This is
  the piece with the most behavioral nuance to preserve — see Task 13's tests.

### Deferred to a follow-up (not in this plan)
- `DeviceConnectionSession` — extracting the connect/reconnect/disconnect
  orchestration currently inline in `ConnectionCubit`. Smaller and lower risk
  than the ShotGraph extraction; sequenced after this plan lands.
- `ShotRepository` (persistence) — no shot history storage exists yet. This
  refactor only reserves the seam: `ShotSnapshot` is the type that would flow
  into it later.

## Naming conventions locked in

- Domain repository interfaces fronting external infrastructure → `*Repository`
  (`ScaleRepository`, `PressureRepository`, future `ShotRepository`).
- Domain interfaces that exist only for test substitutability (no external
  system behind them) → keep the codebase's existing `Abstract*` prefix
  (`AbstractShotClock`, `AbstractAutoTareRule`, `AbstractAutoStartStopRule`).
- Domain classes that react to a stream over time and cause a side effect →
  `*Rule` (`AutoTareRule`, `AutoStartStopRule`).
- Domain classes that synchronously accumulate state and expose a derived
  snapshot → `*Session` (`ShotRecordingSession`).
- Data-layer adapters → unchanged `*Service` suffix (`DecentScaleService`,
  `BookooPressureService`, `BluetoothDevicesService`) — no rename, this term
  was already correct for what they are.

## Non-behavioral cleanups bundled in because they're free

- `lib/devices/models/batter_device_mixin.dart` → `lib/data/models/battery_device_mixin.dart`
  (fixes an existing filename typo while it's already being moved).
- `recorder.dart`'s `import 'package:flutter/material.dart' hide Notification;`
  workaround goes away — it existed only because the app defined its own
  `Notification` class that collided with Flutter's `widgets.dart` one.

## Explicitly not changing

- `AutoTareRule`'s stability-window algorithm, `AutoStartStopRule`'s threshold
  values (including the existing `_treshold1`/`_treshold2` typo — not in scope），
  `ShotClock`'s timer tick interval, and all BLE protocol/byte-parsing code in
  `DecentScaleService`/`BookooPressureService`.
- `ShotGraphCubit`'s public API (`start()`, `restart()`, `close()`) and the
  `ShotGraphState` hierarchy (`ShotGraphInitial`/`Waiting`/`Updating`/`Stopped`).
- One intentional micro-difference: today, `ShotGraphCubit` never clears
  `_weightNotifications`/`_pressureNotifications` on stop (only on the next
  `start()`/`restart()`), leaving them briefly stale in memory. `ShotRecordingSession.stop()`
  preserves this exactly (only nulls the start time) — full clearing stays in
  `reset()`, called from `start()`/`restart()`, matching today's behavior.
