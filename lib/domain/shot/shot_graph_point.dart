class ShotGraphPoint {
  final int millisecond;
  final double value;

  ShotGraphPoint(this.millisecond, this.value);

  factory ShotGraphPoint.fromJson(Map<String, dynamic> json) => ShotGraphPoint(
    json['millisecond'] as int,
    (json['value'] as num).toDouble(),
  );

  Map<String, dynamic> toJson() => {'millisecond': millisecond, 'value': value};
}
