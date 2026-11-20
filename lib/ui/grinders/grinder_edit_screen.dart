import 'package:espresso_log/domain/grinder/grind_setting.dart';
import 'package:espresso_log/domain/grinder/grinder.dart';
import 'package:espresso_log/ui/grinders/grinders_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class GrinderEditScreen extends StatefulWidget {
  const GrinderEditScreen({super.key, this.grinderId});

  final String? grinderId;

  @override
  State<GrinderEditScreen> createState() => _GrinderEditScreenState();
}

class _GrinderEditScreenState extends State<GrinderEditScreen> {
  final _name = TextEditingController();
  final _brand = TextEditingController();
  GrindSettingType _settingType = GrindSettingType.numeric;
  Grinder? _existing;
  bool _initialized = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _name.addListener(() => setState(() {}));
    _brand.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _name.dispose();
    _brand.dispose();
    super.dispose();
  }

  void _init(GrindersState state) {
    if (_initialized) return;
    _initialized = true;
    final id = widget.grinderId;
    if (id == null) return;
    for (final grinder in state.grinders) {
      if (grinder.id == id) {
        _existing = grinder;
        _name.text = grinder.name;
        _brand.text = grinder.brand;
        _settingType = grinder.settingType;
      }
    }
  }

  bool get _canSave =>
      !_busy && _name.text.trim().isNotEmpty && _brand.text.trim().isNotEmpty;

  Future<void> _save() async {
    if (_busy) return;
    setState(() => _busy = true);
    final cubit = context.read<GrindersCubit>();
    final navigator = Navigator.of(context);
    final name = _name.text.trim();
    final brand = _brand.text.trim();
    if (widget.grinderId == null) {
      await cubit.addGrinder(
        name: name,
        brand: brand,
        settingType: _settingType,
      );
    } else {
      Grinder? current;
      for (final grinder in cubit.state.grinders) {
        if (grinder.id == widget.grinderId) current = grinder;
      }
      if (current != null) {
        await cubit.updateGrinder(current.copyWith(name: name, brand: brand));
      }
    }
    navigator.pop();
  }

  Future<void> _archive() async {
    if (_busy) return;
    final cubit = context.read<GrindersCubit>();
    final navigator = Navigator.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Archive grinder?'),
        content: const Text('It will no longer be listed or selectable.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Archive'),
          ),
        ],
      ),
    );
    if (confirmed != true || _busy) return;
    setState(() => _busy = true);
    await cubit.archiveGrinder(widget.grinderId!);
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<GrindersCubit>().state;
    _init(state);
    final notFound = widget.grinderId != null && _existing == null;
    if (notFound) {
      return Scaffold(
        appBar: AppBar(title: const Text('Grinder')),
        body: const Center(child: Text('Grinder not found')),
      );
    }
    final isEdit = _existing != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit grinder' : 'Add grinder'),
        actions: [
          FilledButton(
            onPressed: _canSave ? _save : null,
            child: const Text('Save'),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            key: const Key('grinder-name'),
            controller: _name,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Name'),
          ),
          const SizedBox(height: 16),
          TextField(
            key: const Key('grinder-brand'),
            controller: _brand,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Brand'),
          ),
          const SizedBox(height: 24),
          Text('Setting type', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          SegmentedButton<GrindSettingType>(
            segments: const [
              ButtonSegment(
                value: GrindSettingType.numeric,
                label: Text('Numeric'),
              ),
              ButtonSegment(
                value: GrindSettingType.coarseFine,
                label: Text('Macro + micro'),
              ),
            ],
            selected: {_settingType},
            onSelectionChanged: isEdit
                ? null
                : (selection) => setState(() => _settingType = selection.first),
          ),
          if (isEdit) ...[
            const SizedBox(height: 32),
            OutlinedButton.icon(
              onPressed: _busy ? null : _archive,
              icon: const Icon(Icons.archive_outlined),
              label: const Text('Archive grinder'),
            ),
          ],
        ],
      ),
    );
  }
}
