import 'package:espresso_log/domain/telemetry/scale_repository.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      // Center is a layout widget. It takes a single child and positions it
      // in the middle of the parent.
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          FilledButton(
            onPressed: () => context.push('/settings/log'),
            child: const Text("Logs"),
          ),
          FilledButton(
            onPressed: () => context.push('/settings/recorder'),
            child: const Text("Recorder"),
          ),
          FilledButton(
            onPressed: () => context.read<ScaleRepository>().init(),
            child: const Text("init"),
          ),
          FilledButton(
            onPressed: () => context.read<ScaleRepository>().tareCommand(),
            child: const Text("tare"),
          ),
        ],
      ),
    );
  }
}
