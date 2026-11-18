import 'package:espresso_log/router.dart';
import 'package:espresso_log/ui/grinders/grinders_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class GrindersScreen extends StatelessWidget {
  const GrindersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Grinders')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('${AppRouter.settingsGrindersPath}/new'),
        tooltip: 'Add grinder',
        child: const Icon(Icons.add),
      ),
      body: BlocBuilder<GrindersCubit, GrindersState>(
        builder: (context, state) {
          if (state.grinders.isEmpty) {
            return const Center(child: Text('No grinders yet'));
          }
          final muted = Theme.of(context).colorScheme.onSurfaceVariant;
          return ListView.separated(
            padding: const EdgeInsets.only(top: 8, bottom: 88),
            itemCount: state.grinders.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final grinder = state.grinders[index];
              return ListTile(
                minTileHeight: 64,
                title: Text(
                  grinder.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  grinder.brand,
                  style: TextStyle(color: muted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () => context.push(
                  '${AppRouter.settingsGrindersPath}/${grinder.id}',
                ),
              );
            },
          );
        },
      ),
    );
  }
}
