# espresso_log

Another espresso logging app, mind it is still WiP. Currently it requires both a Decent Scale and a Bookoo Pressure Sensor.

I tried several other apps but they where adding steps to my workflow instead of simplifying it.
The goal of this app is to provide shot metrics without being in the way of making espresso.

## Features
Devices supported: 
- Connect to Decent Espresso Scale
- Connect to Bookoo Pressure Sensor

Metrics:
- Current weight
- Weight change (g/s) 
- Current pressure
- Shot timer
- Graph of:
  - Weight
  - Pressure

Other features:
- Automatically tare the scale after putting cups on it
- Automatically start and stop timer

## Future plans

Stabilize:
- Disconnect pressure device after inactivity
- Keep app always on
- Fix tare logic in graph 
- Smooth graph
- Improve error handling
- Increase test coverage and refactor where needed

Storing shot data:
- Export shot data
- Store shot data
- Display historic shots
- Show reference shot in graph

Support more devices:
- Onboarding flow
- Add other scales/pressure sensors
- Manage devices via settings screen

Store other data:
- Beans
- Grinder settings
- Grams beans in
- Tasting notes

## Development
- install FVM
- run `fvm flutter pub get`
- run `fvm dart run tools/setup_git_hooks.dart`

