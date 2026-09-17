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
