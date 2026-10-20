import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:espresso_log/domain/shot/abstract_shot_clock.dart';
import 'package:espresso_log/domain/telemetry/pressure_repository.dart';
import 'package:espresso_log/domain/telemetry/scale_repository.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
    scaleSubscription?.cancel();
    timerSubscription?.cancel();
    pressureSubscription?.cancel();
    super.dispose();
  }

  bool get _recording => scaleSubscription != null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.pop()),
        title: const Text('Recorder'),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: Icon(
              _recording ? Icons.fiber_manual_record : Icons.stop_circle,
              color: _recording ? Colors.red : null,
            ),
            title: Text(_recording ? 'Recording' : 'Not recording'),
            subtitle: Text('${_events.length} events'),
          ),
          ListTile(
            leading: const Icon(Icons.play_arrow),
            title: const Text('Start recording'),
            enabled: !_recording,
            onTap: _listen,
          ),
          ListTile(
            leading: const Icon(Icons.stop),
            title: const Text('Stop recording'),
            enabled: _recording,
            onTap: _stopListening,
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline),
            title: const Text('Flush recordings'),
            enabled: _events.isNotEmpty,
            onTap: _clear,
          ),
          ListTile(
            leading: const Icon(Icons.ios_share),
            title: const Text('Export recordings'),
            enabled: _events.isNotEmpty,
            onTap: _export,
          ),
        ],
      ),
    );
  }

  void _listen() {
    if (_recording) return;
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
    setState(() {});
  }

  void _stopListening() {
    scaleSubscription?.cancel();
    timerSubscription?.cancel();
    pressureSubscription?.cancel();
    scaleSubscription = null;
    timerSubscription = null;
    pressureSubscription = null;
    setState(() {});
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
