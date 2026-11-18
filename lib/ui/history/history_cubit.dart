import 'package:espresso_log/domain/bean/bean.dart';
import 'package:espresso_log/domain/bean/bean_repository.dart';
import 'package:espresso_log/domain/grinder/grinder.dart';
import 'package:espresso_log/domain/grinder/grinder_repository.dart';
import 'package:espresso_log/domain/shot/shot_list_item.dart';
import 'package:espresso_log/domain/shot/shot_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HistoryEntry {
  final ShotListItem item;
  final Bean? bean;
  final Grinder? grinder;

  const HistoryEntry(this.item, this.bean, this.grinder);
}

class HistoryCubit extends Cubit<List<HistoryEntry>?> {
  final ShotRepository _shots;
  final BeanRepository _beans;
  final GrinderRepository _grinders;

  HistoryCubit(this._shots, this._beans, this._grinders) : super(null);

  Future<void> load() async {
    final items = await _shots.list();
    final beans = {for (final bean in await _beans.list()) bean.id: bean};
    final grinders = {
      for (final grinder in await _grinders.list()) grinder.id: grinder,
    };
    emit([
      for (final item in items)
        HistoryEntry(item, beans[item.beanId], grinders[item.grinderId]),
    ]);
  }
}
