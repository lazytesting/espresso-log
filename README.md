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
- Manage beans and select the bean and dose (grams in) per shot; shown with the ratio in history
- Automatically tare the scale after putting cups on it
- Automatically start and stop timer

## Future plans


Storing shot data:
- Show reference shot in graph

Support more devices:
- Add other scales/pressure sensors

Store other data:
- Grinder settings
- Tasting notes

## Development
- install FVM
- run `fvm flutter pub get`
- run `fvm dart run tools/setup_git_hooks.dart`

