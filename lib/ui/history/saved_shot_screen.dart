import 'dart:convert';
import 'dart:io';

import 'package:espresso_log/domain/bean/bean.dart';
import 'package:espresso_log/domain/bean/bean_repository.dart';
import 'package:espresso_log/domain/shot/recorded_shot.dart';
import 'package:espresso_log/domain/shot/shot_repository.dart';
import 'package:espresso_log/ui/history/history.dart';
import 'package:espresso_log/ui/shot/shot_result_view.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

class SavedShotScreen extends StatelessWidget {
  final String shotId;

  const SavedShotScreen({super.key, required this.shotId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_LoadedShot?>(
      future: _load(context),
      builder: (context, snapshot) {
        final loaded = snapshot.data;
        final shot = loaded?.shot;
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
                  onPressed: () => _share(context, shot),
                ),
            ],
          ),
          body: switch (snapshot.connectionState) {
            ConnectionState.done when shot == null => const Center(
              child: Text('Shot not found'),
            ),
            ConnectionState.done => ShotResultView(
              snapshot: shot!.snapshot,
              bean: loaded!.bean,
              doseGrams: shot.doseGrams,
            ),
            _ => const Center(child: CircularProgressIndicator()),
          },
        );
      },
    );
  }

  Future<_LoadedShot?> _load(BuildContext context) async {
    final shots = context.read<ShotRepository>();
    final beans = context.read<BeanRepository>();
    final shot = await shots.get(shotId);
    if (shot == null) return null;
    final beanId = shot.beanId;
    final bean = beanId == null ? null : await beans.get(beanId);
    return _LoadedShot(shot, bean);
  }

  Future<void> _share(BuildContext context, RecordedShot shot) async {
    final beanId = shot.beanId;
    final bean = beanId == null
        ? null
        : await context.read<BeanRepository>().get(beanId);
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/espresso_shot_${shot.id}.json');
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(shot.toExportJson(bean: bean)),
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

class _LoadedShot {
  final RecordedShot shot;
  final Bean? bean;

  const _LoadedShot(this.shot, this.bean);
}
