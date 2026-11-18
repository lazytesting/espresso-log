import 'package:equatable/equatable.dart';

import 'grind_setting.dart';

class Grinder extends Equatable {
  final String id;
  final String name;
  final String brand;
  final GrindSettingType settingType;
  final bool archived;

  const Grinder({
    required this.id,
    required this.name,
    required this.brand,
    required this.settingType,
    required this.archived,
  });

  factory Grinder.create({
    required String name,
    required String brand,
    required GrindSettingType settingType,
    DateTime? now,
  }) {
    return Grinder(
      id: (now ?? DateTime.now()).microsecondsSinceEpoch.toString(),
      name: name.trim(),
      brand: brand.trim(),
      settingType: settingType,
      archived: false,
    );
  }

  factory Grinder.fromJson(Map<String, dynamic> json) {
    return Grinder(
      id: json['id'] as String,
      name: json['name'] as String,
      brand: json['brand'] as String,
      settingType: GrindSettingType.values.byName(
        json['settingType'] as String,
      ),
      archived: json['archived'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'brand': brand,
    'settingType': settingType.name,
    'archived': archived,
  };

  /// The setting type is fixed after creation.
  Grinder copyWith({String? name, String? brand, bool? archived}) {
    return Grinder(
      id: id,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      settingType: settingType,
      archived: archived ?? this.archived,
    );
  }

  @override
  List<Object?> get props => [id, name, brand, settingType, archived];
}
