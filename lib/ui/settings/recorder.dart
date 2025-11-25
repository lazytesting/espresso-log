import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:espresso_log/devices/pressure/models/abstract_pressure_service.dart';
import 'package:espresso_log/devices/scale/models/abstract_scale_service.dart';
import 'package:espresso_log/devices/timer/abstract_timer_service.dart';
import 'package:espresso_log/ui/scaffold/screen_container.dart';
import 'package:flutter/material.dart' hide Notification;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

// make all events json serializable
// listen to all streams and add them to a list
// flush list to file

class RecorderScreen extends StatefulWidget {
  const RecorderScreen({super.key});

  @override
  State<RecorderScreen> createState() => _RecorderScreenState();
}

class _RecorderScreenState extends State<RecorderScreen> {
  late final AbstractScaleService _scaleService = context
      .read<AbstractScaleService>();
  late final AbstractTimerService _timerService = context
      .read<AbstractTimerService>();
  late final AbstractPressureService _pressureService = context
      .read<AbstractPressureService>();

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
    return ScreenContainer(title: 'Bla', child: _getScreen(context));
  }

  void _listen() {
    scaleSubscription = _scaleService.stream.listen((event) {
      setState(() {
        _events.add(event.toJson());
      });
    });
    timerSubscription = _timerService.stream.listen((event) {
      setState(() {
        _events.add(event.toJson());
      });
    });
    pressureSubscription = _pressureService.stream.listen((event) {
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

  Widget _getScreen(BuildContext context) {
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
}
