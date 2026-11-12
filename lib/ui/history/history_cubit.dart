import 'package:espresso_log/domain/bean/bean.dart';
import 'package:espresso_log/domain/bean/bean_repository.dart';
import 'package:espresso_log/domain/shot/recorded_shot.dart';
import 'package:espresso_log/domain/shot/shot_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HistoryEntry {
  final RecordedShot shot;
  final Bean? bean;

  const HistoryEntry(this.shot, this.bean);
}

class HistoryCubit extends Cubit<List<HistoryEntry>?> {
  final ShotRepository _shots;
  final BeanRepository _beans;

  HistoryCubit(this._shots, this._beans) : super(null);

  Future<void> load() async {
    final shots = await _shots.list();
    final beans = {for (final bean in await _beans.list()) bean.id: bean};
    emit([for (final shot in shots) HistoryEntry(shot, beans[shot.beanId])]);
  }
}
