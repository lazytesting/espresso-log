import 'package:espresso_log/domain/shot/recorded_shot.dart';
import 'package:espresso_log/domain/shot/shot_repository.dart';
import 'package:espresso_log/ui/history/history_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

String formatShotDate(DateTime date) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${date.year}-${two(date.month)}-${two(date.day)} '
      '${two(date.hour)}:${two(date.minute)}';
}

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => HistoryCubit(context.read<ShotRepository>())..load(),
      child: Scaffold(
        appBar: AppBar(title: const Text('History')),
        body: BlocBuilder<HistoryCubit, List<RecordedShot>?>(
          builder: (context, shots) {
            if (shots == null) {
              return const Center(child: CircularProgressIndicator());
            }
            if (shots.isEmpty) {
              return const Center(child: Text('No saved shots yet'));
            }
            return RefreshIndicator(
              onRefresh: context.read<HistoryCubit>().load,
              child: ListView.builder(
                itemCount: shots.length,
                itemBuilder: (context, index) {
                  final shot = shots[index];
                  return ListTile(
                    title: Text(formatShotDate(shot.recordedAt)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/history/${shot.id}'),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
