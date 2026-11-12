import 'package:equatable/equatable.dart';

import 'dose.dart';

class Bean extends Equatable {
  static const int minRoastLevel = 1;
  static const int maxRoastLevel = 5;
  static const int defaultRoastLevel = 3;

  final String id;
  final String name;
  final String? roaster;
  final int roastLevel;
  final String? notes;
  final bool archived;
  final double doseGrams;

  const Bean({
    required this.id,
    required this.name,
    this.roaster,
    required this.roastLevel,
    this.notes,
    required this.archived,
    required this.doseGrams,
  });

  factory Bean.create({
    required String name,
    String? roaster,
    int roastLevel = defaultRoastLevel,
    String? notes,
    DateTime? now,
  }) {
    return Bean(
      id: (now ?? DateTime.now()).microsecondsSinceEpoch.toString(),
      name: name.trim(),
      roaster: _blankToNull(roaster),
      roastLevel: roastLevel,
      notes: _blankToNull(notes),
      archived: false,
      doseGrams: defaultDoseGrams,
    );
  }

  factory Bean.fromJson(Map<String, dynamic> json) {
    return Bean(
      id: json['id'] as String,
      name: json['name'] as String,
      roaster: json['roaster'] as String?,
      roastLevel: (json['roastLevel'] as num)
          .toInt()
          .clamp(minRoastLevel, maxRoastLevel),
      notes: json['notes'] as String?,
      archived: json['archived'] as bool? ?? false,
      doseGrams: normalizeDose((json['doseGrams'] as num).toDouble()),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'roaster': roaster,
        'roastLevel': roastLevel,
        'notes': notes,
        'archived': archived,
        'doseGrams': doseGrams,
      };

  Bean copyWith({
    String? name,
    String? Function()? roaster,
    int? roastLevel,
    String? Function()? notes,
    bool? archived,
    double? doseGrams,
  }) {
    return Bean(
      id: id,
      name: name ?? this.name,
      roaster: roaster != null ? roaster() : this.roaster,
      roastLevel: roastLevel ?? this.roastLevel,
      notes: notes != null ? notes() : this.notes,
      archived: archived ?? this.archived,
      doseGrams: doseGrams ?? this.doseGrams,
    );
  }

  static String roastLabel(int level) => switch (level) {
        1 => 'Light',
        2 => 'Medium-light',
        3 => 'Medium',
        4 => 'Medium-dark',
        _ => 'Dark',
      };

  static String? _blankToNull(String? text) {
    final trimmed = text?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  @override
  List<Object?> get props =>
      [id, name, roaster, roastLevel, notes, archived, doseGrams];
}
