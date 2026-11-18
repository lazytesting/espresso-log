import 'grind_setting.dart';

class GrindMemoryEntry {
  final String grinderId;
  final String? beanId;
  final GrindSetting setting;
  final DateTime lastUsedAt;

  const GrindMemoryEntry({
    required this.grinderId,
    required this.beanId,
    required this.setting,
    required this.lastUsedAt,
  });
}

/// Remembers the last grind setting used per grinder and bean (a null bean
/// id is the unknown bean).
abstract class GrindMemoryRepository {
  Future<GrindSetting?> settingFor({required String grinderId, String? beanId});

  /// Upserts the setting and sets its last-used time to [now] (default now).
  Future<void> remember({
    required String grinderId,
    String? beanId,
    required GrindSetting setting,
    DateTime? now,
  });

  /// Newest [GrindMemoryEntry.lastUsedAt] first.
  Future<List<GrindMemoryEntry>> entriesFor(String grinderId);
}
