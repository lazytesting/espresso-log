import 'package:espresso_log/domain/grinder/grind_setting.dart';
import 'package:espresso_log/ui/grinders/grinders_cubit.dart';
import 'package:espresso_log/ui/home/setup_label.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class GrindSizeSelector extends StatelessWidget {
  const GrindSizeSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GrindersCubit, GrindersState>(
      builder: (context, state) {
        final setting = state.setting;
        if (setting == null) return const SizedBox.shrink();
        final cubit = context.read<GrindersCubit>();
        return ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 72),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
            child: Row(
              children: [
                const SetupLabel('Grind'),
                const Spacer(),
                IconButton.outlined(
                  icon: const Icon(Icons.remove),
                  onPressed: () => cubit.setSetting(setting.stepped(-1)),
                ),
                InkWell(
                  key: const Key('grind-text'),
                  onTap: () => _edit(context, cubit, setting),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      setting.text,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                ),
                IconButton.outlined(
                  icon: const Icon(Icons.add),
                  onPressed: () => cubit.setSetting(setting.stepped(1)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _edit(
    BuildContext context,
    GrindersCubit cubit,
    GrindSetting setting,
  ) async {
    final picked = await showDialog<GrindSetting>(
      context: context,
      builder: (_) => _GrindPickerDialog(initial: setting),
    );
    if (picked != null) cubit.setSetting(picked);
  }
}

class _GrindPickerDialog extends StatefulWidget {
  const _GrindPickerDialog({required this.initial});

  final GrindSetting initial;

  @override
  State<_GrindPickerDialog> createState() => _GrindPickerDialogState();
}

class _GrindPickerDialogState extends State<_GrindPickerDialog> {
  late int _coarse = widget.initial.coarse;
  late String _fine = widget.initial.fine ?? GrindSetting.fineSteps.first;

  bool get _numeric => widget.initial.type == GrindSettingType.numeric;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Grind'),
      content: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButton<int>(
            key: const Key('grind-coarse'),
            value: _coarse,
            items: [
              for (
                var i = GrindSetting.minCoarse;
                i <= GrindSetting.maxCoarse;
                i++
              )
                DropdownMenuItem(value: i, child: Text('$i')),
            ],
            onChanged: (value) => setState(() => _coarse = value!),
          ),
          if (!_numeric) ...[
            const SizedBox(width: 24),
            DropdownButton<String>(
              key: const Key('grind-fine'),
              value: _fine,
              items: [
                for (final f in GrindSetting.fineSteps)
                  DropdownMenuItem(value: f, child: Text(f)),
              ],
              onChanged: (value) => setState(() => _fine = value!),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(
            _numeric
                ? GrindSetting.numeric(_coarse)
                : GrindSetting.coarseFine(_coarse, _fine),
          ),
          child: const Text('OK'),
        ),
      ],
    );
  }
}
