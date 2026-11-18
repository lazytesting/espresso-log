import 'package:espresso_log/domain/grinder/grind_memory_repository.dart';
import 'package:espresso_log/domain/grinder/grind_setting.dart';

class InMemoryGrindMemoryRepository implements GrindMemoryRepository {
  final Map<(String, String), GrindMemoryEntry> entries = {};

  @override
  Future<GrindSetting?> settingFor({
    required String grinderId,
    String? beanId,
  }) async => entries[(grinderId, beanId ?? '')]?.setting;

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
  Future<List<GrindMemoryEntry>> entriesFor(String grinderId) async =>
      entries.values.where((e) => e.grinderId == grinderId).toList()
        ..sort((a, b) => b.lastUsedAt.compareTo(a.lastUsedAt));
}
