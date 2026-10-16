import 'package:espresso_log/domain/settings/settings_repository.dart';
import 'package:espresso_log/domain/telemetry/scale_repository.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late int _startDelayCompensation = context
      .read<SettingsRepository>()
      .startDelayCompensationSeconds;

  @override
  Widget build(BuildContext context) {
    return Center(
      // Center is a layout widget. It takes a single child and positions it
      // in the middle of the parent.
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          ListTile(
            title: const Text('Short start delay compensation'),
            subtitle: Slider(
              value: _startDelayCompensation.toDouble(),
              min: SettingsRepository.minStartDelayCompensationSeconds
                  .toDouble(),
              max: SettingsRepository.maxStartDelayCompensationSeconds
                  .toDouble(),
              divisions:
                  SettingsRepository.maxStartDelayCompensationSeconds -
                  SettingsRepository.minStartDelayCompensationSeconds,
              label: '$_startDelayCompensation s',
              onChanged: (value) {
                setState(() => _startDelayCompensation = value.round());
                context
                    .read<SettingsRepository>()
                    .setStartDelayCompensationSeconds(value.round());
              },
            ),
            trailing: Text('$_startDelayCompensation s'),
          ),
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
