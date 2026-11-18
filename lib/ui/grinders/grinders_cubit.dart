import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:espresso_log/domain/grinder/grind_memory_repository.dart';
import 'package:espresso_log/domain/grinder/grind_setting.dart';
import 'package:espresso_log/domain/grinder/grinder.dart';
import 'package:espresso_log/domain/grinder/grinder_repository.dart';
import 'package:espresso_log/domain/settings/settings_repository.dart';
import 'package:espresso_log/ui/beans/beans_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'grinders_state.dart';

/// Holds the grinders, the selected grinder and its current grind setting.
///
/// Selecting a bean (or a grinder) loads the remembered setting of that
/// grinder/bean pair. A pair with no history gets a row persisted with the
/// default setting, and `last_used_at` of the pair's row is touched on every
/// bean selection so the most recently used bean is restored on grinder switch.
class GrindersCubit extends Cubit<GrindersState> {
  GrindersCubit(this._grinders, this._memory, this._settings, this._beans)
    : _lastBeanId = _beans.state.selectedBeanId,
      super(const GrindersState()) {
    _beanSubscription = _beans.stream.listen(_onBeansChanged);
  }

  final GrinderRepository _grinders;
  final GrindMemoryRepository _memory;
  final SettingsRepository _settings;
  final BeansCubit _beans;
  late final StreamSubscription<BeansState> _beanSubscription;

  /// Bean id last accounted for, so only real bean changes (and not our own
  /// `select` calls, which already load the setting) trigger a reload.
  String? _lastBeanId;

  /// Bumped by every operation that loads a setting; stale loads are dropped.
  int _gen = 0;

  Future<void> load() async {
    final gen = ++_gen;
    final grinders = (await _grinders.list())
        .where((g) => !g.archived)
        .toList();
    final storedId = _settings.selectedGrinderId;
    final selected = _find(grinders, storedId);
    _lastBeanId = _beans.state.selectedBeanId;
    emit(
      GrindersState(
        loaded: true,
        grinders: grinders,
        selectedGrinderId: selected?.id,
        setting: selected == null
            ? null
            : await _loadSetting(selected, _lastBeanId, gen),
      ),
    );
  }

  Future<void> select(String? grinderId) async {
    final gen = ++_gen;
    final grinder = _find(state.grinders, grinderId);
    await _settings.setSelectedGrinderId(grinder?.id);
    if (gen != _gen) return;
    if (grinder == null) {
      emit(GrindersState(loaded: state.loaded, grinders: state.grinders));
      return;
    }
    final entries = await _memory.entriesFor(grinder.id);
    if (gen != _gen) return;
    for (final entry in entries) {
      final beanId = entry.beanId;
      if (beanId == null || _beans.state.beans.any((b) => b.id == beanId)) {
        // Set before selecting so the bean listener ignores our own change.
        _lastBeanId = beanId;
        await _beans.select(beanId);
        break;
      }
    }
    if (gen != _gen) return;
    _lastBeanId = _beans.state.selectedBeanId;
    final setting = await _loadSetting(grinder, _lastBeanId, gen);
    if (setting == null) return;
    emit(_copy(selectedGrinderId: grinder.id, setting: setting));
  }

  Future<void> setSetting(GrindSetting setting) async {
    final grinder = state.selectedGrinder;
    if (grinder == null) return;
    emit(_copy(selectedGrinderId: grinder.id, setting: setting));
    await _memory.remember(
      grinderId: grinder.id,
      beanId: _beans.state.selectedBeanId,
      setting: setting,
    );
  }

  Future<Grinder> addGrinder({
    required String name,
    required String brand,
    required GrindSettingType settingType,
  }) async {
    final grinder = Grinder.create(
      name: name,
      brand: brand,
      settingType: settingType,
    );
    await _grinders.save(grinder);
    emit(_copy(grinders: _sorted([...state.grinders, grinder])));
    return grinder;
  }

  Future<void> updateGrinder(Grinder grinder) async {
    await _grinders.save(grinder);
    emit(
      _copy(
        grinders: _sorted([
          for (final g in state.grinders) g.id == grinder.id ? grinder : g,
        ]),
      ),
    );
  }

  Future<void> archiveGrinder(String id) async {
    final grinder = _find(state.grinders, id);
    if (grinder == null) return;
    await _grinders.save(grinder.copyWith(archived: true));
    final grinders = state.grinders.where((g) => g.id != id).toList();
    if (state.selectedGrinderId == id) {
      emit(GrindersState(loaded: state.loaded, grinders: grinders));
      await _settings.setSelectedGrinderId(null);
    } else {
      emit(_copy(grinders: grinders));
    }
  }

  @override
  Future<void> close() async {
    await _beanSubscription.cancel();
    return super.close();
  }

  Future<void> _onBeansChanged(BeansState beans) async {
    if (beans.selectedBeanId == _lastBeanId) return;
    _lastBeanId = beans.selectedBeanId;
    final grinder = state.selectedGrinder;
    if (grinder == null) return;
    final gen = ++_gen;
    final setting = await _loadSetting(grinder, beans.selectedBeanId, gen);
    if (setting == null) return;
    emit(_copy(selectedGrinderId: grinder.id, setting: setting));
  }

  /// The remembered setting for [grinder] and [beanId]. Creates the memory
  /// row with the default setting when the pair has none yet, otherwise
  /// re-remembers it to refresh its last-used time. Returns null
  /// (without writing) when superseded by a newer operation ([gen]).
  Future<GrindSetting?> _loadSetting(
    Grinder grinder,
    String? beanId,
    int gen,
  ) async {
    final remembered = await _memory.settingFor(
      grinderId: grinder.id,
      beanId: beanId,
    );
    if (isClosed || gen != _gen) return null;
    if (remembered != null) {
      // Touch last_used_at (the port has no touch-only method).
      await _memory.remember(
        grinderId: grinder.id,
        beanId: beanId,
        setting: remembered,
      );
      if (isClosed || gen != _gen) return null;
      return remembered;
    }
    final setting = GrindSetting.defaultFor(grinder.settingType);
    await _memory.remember(
      grinderId: grinder.id,
      beanId: beanId,
      setting: setting,
    );
    if (isClosed || gen != _gen) return null;
    return setting;
  }

  static Grinder? _find(List<Grinder> grinders, String? id) {
    if (id == null) return null;
    for (final grinder in grinders) {
      if (grinder.id == id) return grinder;
    }
    return null;
  }

  static List<Grinder> _sorted(List<Grinder> grinders) =>
      grinders
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

  GrindersState _copy({
    List<Grinder>? grinders,
    String? selectedGrinderId,
    GrindSetting? setting,
  }) => GrindersState(
    loaded: state.loaded,
    grinders: grinders ?? state.grinders,
    selectedGrinderId: selectedGrinderId ?? state.selectedGrinderId,
    setting: setting ?? state.setting,
  );
}
