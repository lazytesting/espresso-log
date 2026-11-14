import 'package:espresso_log/domain/bean/bean.dart';
import 'package:espresso_log/router.dart';
import 'package:espresso_log/ui/beans/beans_cubit.dart';
import 'package:espresso_log/ui/history/shot_bean_labels.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class BeansScreen extends StatelessWidget {
  const BeansScreen({super.key});

  static String subtitle(Bean bean) => [
    if (bean.roaster != null) bean.roaster!,
    Bean.roastLabel(bean.roastLevel),
  ].join(' · ');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Beans')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('${AppRouter.beansPath}/new'),
        tooltip: 'Add bean',
        child: const Icon(Icons.add),
      ),
      body: BlocBuilder<BeansCubit, BeansState>(
        builder: (context, state) {
          if (state.beans.isEmpty) {
            return const Center(child: Text('No beans yet'));
          }
          final theme = Theme.of(context);
          final muted = theme.colorScheme.onSurfaceVariant;
          return ListView.separated(
            padding: const EdgeInsets.only(top: 8, bottom: 88),
            itemCount: state.beans.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final bean = state.beans[index];
              return ListTile(
                minTileHeight: 64,
                title: Text(
                  bean.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  subtitle(bean),
                  style: TextStyle(color: muted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Text(
                  formatDose(bean.doseGrams),
                  style: theme.textTheme.bodyLarge?.copyWith(color: muted),
                ),
                onTap: () => context.push('${AppRouter.beansPath}/${bean.id}'),
              );
            },
          );
        },
      ),
    );
  }
}
