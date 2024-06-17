abstract class ScaleNotification {
  final DateTime timeStamp;

  ScaleNotification({required this.timeStamp});
}

class WeightNotification extends ScaleNotification {
  final double weight;
  final bool isStable;

  WeightNotification(
      {required this.weight, required this.isStable, required super.timeStamp});
}

class TareNotification extends ScaleNotification {
  TareNotification({required super.timeStamp});
}
