import 'package:espresso_log/domain/bean/bean.dart';
import 'package:espresso_log/router.dart';
import 'package:espresso_log/ui/beans/beans_cubit.dart';
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('${AppRouter.beansPath}/new'),
        icon: const Icon(Icons.add),
        label: const Text('Add bean'),
      ),
      body: BlocBuilder<BeansCubit, BeansState>(
        builder: (context, state) {
          if (state.beans.isEmpty) {
            return const Center(child: Text('No beans yet'));
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
            itemCount: state.beans.length,
            itemBuilder: (context, index) {
              final bean = state.beans[index];
              return Card(
                child: ListTile(
                  title: Text(bean.name),
                  subtitle: Text(subtitle(bean)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () =>
                      context.push('${AppRouter.beansPath}/${bean.id}'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
