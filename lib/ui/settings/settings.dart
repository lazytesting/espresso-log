import 'package:espresso_log/domain/settings/settings_repository.dart';
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
    return ListView(
      children: [
        if (_restartRequired)
          const ListTile(
            leading: Icon(Icons.restart_alt),
            title: Text('Restart the app to apply device changes'),
          ),
        const _SectionHeader('Pressure device'),
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
              DropdownMenuItem(value: PressureSource.mock, child: Text('Mock')),
            ],
          ),
        ),
        ListTile(
          title: const Text('Short start delay compensation'),
          subtitle: Slider(
            value: _startDelayCompensation.toDouble(),
            min: SettingsRepository.minStartDelayCompensationSeconds.toDouble(),
            max: SettingsRepository.maxStartDelayCompensationSeconds.toDouble(),
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
        const _SectionHeader('Scale'),
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
                child: Text('Decent Scale'),
              ),
              DropdownMenuItem(value: ScaleSource.mock, child: Text('Mock')),
            ],
          ),
        ),
        const _SectionHeader('Developer tools'),
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
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
