import 'package:equatable/equatable.dart';
import 'package:espresso_log/domain/bean/bean.dart';
import 'package:espresso_log/domain/bean/bean_repository.dart';
import 'package:espresso_log/domain/bean/dose.dart';
import 'package:espresso_log/domain/settings/settings_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'beans_state.dart';

class BeansCubit extends Cubit<BeansState> {
  BeansCubit(this._beans, this._settings) : super(const BeansState());

  final BeanRepository _beans;
  final SettingsRepository _settings;

  Future<void> load() async {
    final beans = (await _beans.list()).where((b) => !b.archived).toList();
    final storedId = _settings.selectedBeanId;
    final selected = _find(beans, storedId);
    emit(
      BeansState(
        loaded: true,
        beans: beans,
        selectedBeanId: selected?.id,
        doseGrams: selected?.doseGrams ?? _settings.unknownBeanDoseGrams,
      ),
    );
  }

  Future<void> select(String? beanId) async {
    final selected = _find(state.beans, beanId);
    emit(
      BeansState(
        loaded: state.loaded,
        beans: state.beans,
        selectedBeanId: selected?.id,
        doseGrams: selected?.doseGrams ?? _settings.unknownBeanDoseGrams,
      ),
    );
    await _settings.setSelectedBeanId(selected?.id);
  }

  Future<void> setDose(double grams) async {
    final dose = normalizeDose(grams);
    final selected = state.selectedBean;
    if (selected == null) {
      emit(_copy(doseGrams: dose));
      await _settings.setUnknownBeanDoseGrams(dose);
      return;
    }
    final updated = selected.copyWith(doseGrams: dose);
    emit(_copy(beans: _replace(updated), doseGrams: dose));
    await _beans.save(updated);
  }

  Future<Bean> addBean({
    required String name,
    String? roaster,
    required int roastLevel,
    String? notes,
  }) async {
    final bean = Bean.create(
      name: name,
      roaster: roaster,
      roastLevel: roastLevel,
      notes: notes,
    );
    await _beans.save(bean);
    emit(_copy(beans: _sorted([...state.beans, bean])));
    return bean;
  }

  Future<void> updateBean(Bean bean) async {
    await _beans.save(bean);
    emit(
      _copy(
        beans: _replace(bean),
        doseGrams: bean.id == state.selectedBeanId ? bean.doseGrams : null,
      ),
    );
  }

  Future<void> archiveBean(String id) async {
    final bean = _find(state.beans, id);
    if (bean == null) return;
    await _beans.save(bean.copyWith(archived: true));
    final beans = state.beans.where((b) => b.id != id).toList();
    if (state.selectedBeanId == id) {
      emit(
        BeansState(
          loaded: state.loaded,
          beans: beans,
          selectedBeanId: null,
          doseGrams: _settings.unknownBeanDoseGrams,
        ),
      );
      await _settings.setSelectedBeanId(null);
    } else {
      emit(_copy(beans: beans));
    }
  }

  static Bean? _find(List<Bean> beans, String? id) {
    if (id == null) return null;
    for (final bean in beans) {
      if (bean.id == id) return bean;
    }
    return null;
  }

  static List<Bean> _sorted(List<Bean> beans) =>
      beans
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

  List<Bean> _replace(Bean bean) =>
      _sorted([for (final b in state.beans) b.id == bean.id ? bean : b]);

  BeansState _copy({List<Bean>? beans, double? doseGrams}) => BeansState(
    loaded: state.loaded,
    beans: beans ?? state.beans,
    selectedBeanId: state.selectedBeanId,
    doseGrams: doseGrams ?? state.doseGrams,
  );
}
