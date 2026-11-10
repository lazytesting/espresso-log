import 'dart:convert';
import 'dart:io';

import 'package:espresso_log/domain/shot/recorded_shot.dart';
import 'package:espresso_log/domain/shot/shot_repository.dart';
import 'package:espresso_log/ui/history/history.dart';
import 'package:espresso_log/ui/shot/shot_graph/shot_graph_widget.dart';
import 'package:espresso_log/ui/shot/shot_metrics_widget.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

class SavedShotScreen extends StatelessWidget {
  final String shotId;

  const SavedShotScreen({super.key, required this.shotId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<RecordedShot?>(
      future: context.read<ShotRepository>().get(shotId),
      builder: (context, snapshot) {
        final shot = snapshot.data;
        return Scaffold(
          appBar: AppBar(
            title: Text(
              shot == null ? 'Shot' : formatShotDate(shot.recordedAt),
            ),
            actions: [
              if (shot != null)
                IconButton(
                  icon: const Icon(Icons.ios_share),
                  tooltip: 'Share as JSON',
                  onPressed: () => _share(shot),
                ),
            ],
          ),
          body: switch (snapshot.connectionState) {
            ConnectionState.done when shot == null => const Center(
              child: Text('Shot not found'),
            ),
            ConnectionState.done => Column(
              children: [
                ShotSummaryWidget(shot!.snapshot.summary),
                Expanded(
                  child: ShotGraph(
                    weightData: shot.snapshot.weightData,
                    pressureData: shot.snapshot.pressureData,
                  ),
                ),
              ],
            ),
            _ => const Center(child: CircularProgressIndicator()),
          },
        );
      },
    );
  }

  Future<void> _share(RecordedShot shot) async {
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/espresso_shot_${shot.id}.json');
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(shot.toJson()),
    );
    await SharePlus.instance.share(
      ShareParams(
        text: 'Espresso shot ${formatShotDate(shot.recordedAt)}',
        files: [XFile(file.path)],
        subject: 'Espresso Log shot',
      ),
    );
  }
}
