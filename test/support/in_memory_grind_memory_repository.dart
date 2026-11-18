import 'package:espresso_log/domain/grinder/grind_memory_repository.dart';
import 'package:espresso_log/domain/grinder/grind_setting.dart';
import 'package:espresso_log/domain/grinder/grinder_repository.dart';

/// Mirrors the Drift repository: unknown grinders (not in [_grinders]) yield
/// null / an empty list, and ties in lastUsedAt are ordered by bean key
/// ascending (unknown bean first).
class InMemoryGrindMemoryRepository implements GrindMemoryRepository {
  final GrinderRepository _grinders;
  final Map<(String, String), GrindMemoryEntry> entries = {};

  InMemoryGrindMemoryRepository(this._grinders);

  @override
  Future<GrindSetting?> settingFor({
    required String grinderId,
    String? beanId,
  }) async {
    if (await _grinders.get(grinderId) == null) return null;
    return entries[(grinderId, beanId ?? '')]?.setting;
  }

  @override
  Future<void> remember({
    required String grinderId,
    String? beanId,
    required GrindSetting setting,
    DateTime? now,
  }) async {
    entries[(grinderId, beanId ?? '')] = GrindMemoryEntry(
      grinderId: grinderId,
      beanId: beanId,
      setting: setting,
      lastUsedAt: now ?? DateTime.now(),
    );
  }

  @override
  Future<List<GrindMemoryEntry>> entriesFor(String grinderId) async {
    if (await _grinders.get(grinderId) == null) return [];
    return entries.values.where((e) => e.grinderId == grinderId).toList()
      ..sort((a, b) {
        final byTime = b.lastUsedAt.compareTo(a.lastUsedAt);
        return byTime != 0
            ? byTime
            : (a.beanId ?? '').compareTo(b.beanId ?? '');
      });
  }
}
