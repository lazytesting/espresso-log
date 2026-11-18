import 'package:espresso_log/router.dart';
import 'package:espresso_log/ui/grinders/grinders_cubit.dart';
import 'package:espresso_log/ui/home/setup_label.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class GrinderSelector extends StatelessWidget {
  const GrinderSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GrindersCubit, GrindersState>(
      builder: (context, state) {
        final grinder = state.selectedGrinder;
        final theme = Theme.of(context);
        return InkWell(
          onTap: () => _openSheet(context),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 72),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
              child: Row(
                children: [
                  const SetupLabel('Grinder'),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          grinder?.name ?? 'Unknown grinder',
                          style: theme.textTheme.titleMedium,
                          textAlign: TextAlign.end,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (grinder != null)
                          Text(
                            grinder.brand,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.end,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _openSheet(BuildContext context) {
    final cubit = context.read<GrindersCubit>();
    return showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        final state = cubit.state;
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              for (final grinder in state.grinders)
                _entry(
                  sheetContext,
                  cubit,
                  id: grinder.id,
                  title: grinder.name,
                  subtitle: grinder.brand,
                  selected: grinder.id == state.selectedGrinderId,
                ),
              _entry(
                sheetContext,
                cubit,
                id: null,
                title: 'Unknown grinder',
                selected: state.selectedGrinderId == null,
              ),
              ListTile(
                leading: const Icon(Icons.add),
                title: const Text('Add grinder'),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  context.push('${AppRouter.settingsGrindersPath}/new');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _entry(
    BuildContext sheetContext,
    GrindersCubit cubit, {
    required String? id,
    required String title,
    String? subtitle,
    required bool selected,
  }) {
    return ListTile(
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle),
      trailing: selected ? const Icon(Icons.check) : null,
      onTap: () {
        cubit.select(id);
        Navigator.of(sheetContext).pop();
      },
    );
  }
}
