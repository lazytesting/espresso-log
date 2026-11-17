import 'package:espresso_log/domain/settings/settings_repository.dart';
import 'package:espresso_log/ui/components/section_header.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final SettingsRepository _settings = context.read<SettingsRepository>();
  late int _startDelayCompensation = _settings.startDelayCompensationSeconds;
  late ScaleSource _scaleSource = _settings.scaleSource;
  late PressureSource _pressureSource = _settings.pressureSource;
  late final ScaleSource _initialScaleSource = _scaleSource;
  late final PressureSource _initialPressureSource = _pressureSource;

  bool get _restartRequired =>
      _scaleSource != _initialScaleSource ||
      _pressureSource != _initialPressureSource;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          if (_restartRequired)
            const ListTile(
              leading: Icon(Icons.restart_alt),
              title: Text('Restart the app to apply device changes'),
            ),
          const SectionHeader('Scale'),
          ListTile(
            title: const Text('Device'),
            trailing: DropdownButton<ScaleSource>(
              value: _scaleSource,
              onChanged: (source) {
                if (source == null) return;
                setState(() => _scaleSource = source);
                _settings.setScaleSource(source);
              },
              items: const [
                DropdownMenuItem(
                  value: ScaleSource.decent,
                  child: Text('Decent scale'),
                ),
                DropdownMenuItem(value: ScaleSource.mock, child: Text('Mock')),
              ],
            ),
          ),
          const SectionHeader('Pressure sensor'),
          ListTile(
            title: const Text('Device'),
            trailing: DropdownButton<PressureSource>(
              value: _pressureSource,
              onChanged: (source) {
                if (source == null) return;
                setState(() => _pressureSource = source);
                _settings.setPressureSource(source);
              },
              items: const [
                DropdownMenuItem(
                  value: PressureSource.bookoo,
                  child: Text('Bookoo pressure sensor'),
                ),
                DropdownMenuItem(
                  value: PressureSource.mock,
                  child: Text('Mock'),
                ),
              ],
            ),
          ),
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
                _settings.setStartDelayCompensationSeconds(value.round());
              },
            ),
            trailing: Text('$_startDelayCompensation s'),
          ),
          const SectionHeader('Developer tools'),
          ListTile(
            leading: const Icon(Icons.article_outlined),
            title: const Text('Logs'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/settings/log'),
          ),
          ListTile(
            leading: const Icon(Icons.fiber_manual_record_outlined),
            title: const Text('Recorder'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/settings/recorder'),
          ),
        ],
      ),
    );
  }
}
