abstract class ScaleNotification {
  final DateTime timeStamp;

  ScaleNotification({required this.timeStamp});
}

class WeightNotification extends ScaleNotification {
  final double weight;

  WeightNotification({required this.weight, required super.timeStamp});
}

class TareNotification extends ScaleNotification {
  TareNotification({required super.timeStamp});
}
