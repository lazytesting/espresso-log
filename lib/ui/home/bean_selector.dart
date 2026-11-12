import 'package:espresso_log/domain/bean/bean.dart';
import 'package:espresso_log/ui/beans/beans_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class BeanSelector extends StatelessWidget {
  const BeanSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BeansCubit, BeansState>(
      builder: (context, state) {
        final bean = state.selectedBean;
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ListTile(
            title: Text(bean?.name ?? 'Unknown bean'),
            subtitle: bean == null ? null : Text(_subtitle(bean)),
            leading: const Text('Bean'),
            trailing: const Icon(Icons.arrow_drop_down),
            onTap: () => _openSheet(context),
          ),
        );
      },
    );
  }

  static String _subtitle(Bean bean) {
    final label = Bean.roastLabel(bean.roastLevel);
    return bean.roaster == null ? label : '${bean.roaster} · $label';
  }

  Future<void> _openSheet(BuildContext context) {
    final cubit = context.read<BeansCubit>();
    return showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        final state = cubit.state;
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              for (final bean in state.beans)
                _entry(
                  sheetContext,
                  cubit,
                  id: bean.id,
                  title: bean.name,
                  subtitle: _subtitle(bean),
                  selected: bean.id == state.selectedBeanId,
                ),
              _entry(
                sheetContext,
                cubit,
                id: null,
                title: 'Unknown bean',
                selected: state.selectedBeanId == null,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _entry(
    BuildContext sheetContext,
    BeansCubit cubit, {
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
