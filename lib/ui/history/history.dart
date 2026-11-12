import 'package:espresso_log/domain/bean/bean_repository.dart';
import 'package:espresso_log/domain/shot/shot_repository.dart';
import 'package:espresso_log/ui/history/history_cubit.dart';
import 'package:espresso_log/ui/history/shot_bean_labels.dart';
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
      create: (context) => HistoryCubit(
        context.read<ShotRepository>(),
        context.read<BeanRepository>(),
      )..load(),
      child: Scaffold(
        appBar: AppBar(title: const Text('History')),
        body: BlocBuilder<HistoryCubit, List<HistoryEntry>?>(
          builder: (context, entries) {
            if (entries == null) {
              return const Center(child: CircularProgressIndicator());
            }
            if (entries.isEmpty) {
              return const Center(child: Text('No saved shots yet'));
            }
            return RefreshIndicator(
              onRefresh: context.read<HistoryCubit>().load,
              child: ListView.builder(
                itemCount: entries.length,
                itemBuilder: (context, index) {
                  final entry = entries[index];
                  final shot = entry.shot;
                  final subtitle = historySubtitle(shot, entry.bean);
                  return ListTile(
                    title: Text(formatShotDate(shot.recordedAt)),
                    subtitle: subtitle == null ? null : Text(subtitle),
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
