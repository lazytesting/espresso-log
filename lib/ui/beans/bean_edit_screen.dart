import 'package:espresso_log/domain/bean/bean.dart';
import 'package:espresso_log/ui/beans/beans_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class BeanEditScreen extends StatefulWidget {
  const BeanEditScreen({super.key, this.beanId});

  final String? beanId;

  @override
  State<BeanEditScreen> createState() => _BeanEditScreenState();
}

class _BeanEditScreenState extends State<BeanEditScreen> {
  final _name = TextEditingController();
  final _roaster = TextEditingController();
  final _notes = TextEditingController();
  int _roastLevel = Bean.defaultRoastLevel;
  Bean? _existing;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _name.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _name.dispose();
    _roaster.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _init(BeansState state) {
    if (_initialized) return;
    _initialized = true;
    final id = widget.beanId;
    if (id == null) return;
    for (final bean in state.beans) {
      if (bean.id == id) {
        _existing = bean;
        _name.text = bean.name;
        _roaster.text = bean.roaster ?? '';
        _notes.text = bean.notes ?? '';
        _roastLevel = bean.roastLevel;
      }
    }
  }

  Future<void> _save() async {
    final cubit = context.read<BeansCubit>();
    final navigator = Navigator.of(context);
    final name = _name.text.trim();
    final roaster = _roaster.text.trim();
    final notes = _notes.text.trim();
    final existing = _existing;
    if (existing == null) {
      await cubit.addBean(
        name: name,
        roaster: roaster,
        roastLevel: _roastLevel,
        notes: notes,
      );
    } else {
      await cubit.updateBean(
        existing.copyWith(
          name: name,
          roaster: () => roaster.isEmpty ? null : roaster,
          roastLevel: _roastLevel,
          notes: () => notes.isEmpty ? null : notes,
        ),
      );
    }
    navigator.pop();
  }

  Future<void> _archive() async {
    final cubit = context.read<BeansCubit>();
    final navigator = Navigator.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Archive bean?'),
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
    if (confirmed != true) return;
    await cubit.archiveBean(widget.beanId!);
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<BeansCubit>().state;
    _init(state);
    final notFound = widget.beanId != null && _existing == null;
    if (notFound) {
      return Scaffold(
        appBar: AppBar(title: const Text('Bean')),
        body: const Center(child: Text('Bean not found')),
      );
    }
    final isEdit = _existing != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit bean' : 'Add bean'),
        actions: [
          TextButton(
            onPressed: _name.text.trim().isEmpty ? null : _save,
            child: const Text('Save'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            key: const Key('bean-name'),
            controller: _name,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Name'),
          ),
          const SizedBox(height: 16),
          TextField(
            key: const Key('bean-roaster'),
            controller: _roaster,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Roaster'),
          ),
          const SizedBox(height: 24),
          Text('Roast profile', style: Theme.of(context).textTheme.titleSmall),
          Slider(
            min: Bean.minRoastLevel.toDouble(),
            max: Bean.maxRoastLevel.toDouble(),
            divisions: Bean.maxRoastLevel - Bean.minRoastLevel,
            value: _roastLevel.toDouble(),
            label: Bean.roastLabel(_roastLevel),
            onChanged: (v) => setState(() => _roastLevel = v.round()),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [Text('Light'), Text('Dark')],
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            key: const Key('bean-notes'),
            controller: _notes,
            minLines: 3,
            maxLines: 6,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Notes',
              alignLabelWithHint: true,
            ),
          ),
          if (isEdit) ...[
            const SizedBox(height: 32),
            OutlinedButton.icon(
              onPressed: _archive,
              icon: const Icon(Icons.archive_outlined),
              label: const Text('Archive bean'),
            ),
          ],
        ],
      ),
    );
  }
}
