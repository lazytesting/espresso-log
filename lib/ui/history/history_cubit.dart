import 'package:espresso_log/domain/bean/bean.dart';
import 'package:espresso_log/domain/bean/bean_repository.dart';
import 'package:espresso_log/domain/shot/shot_list_item.dart';
import 'package:espresso_log/domain/shot/shot_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HistoryEntry {
  final ShotListItem item;
  final Bean? bean;

  const HistoryEntry(this.item, this.bean);
}

class HistoryCubit extends Cubit<List<HistoryEntry>?> {
  final ShotRepository _shots;
  final BeanRepository _beans;

  HistoryCubit(this._shots, this._beans) : super(null);

  Future<void> load() async {
    final items = await _shots.list();
    final beans = {for (final bean in await _beans.list()) bean.id: bean};
    emit([for (final item in items) HistoryEntry(item, beans[item.beanId])]);
  }
}
