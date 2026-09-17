import 'package:espresso_log/domain/telemetry/pressure_reading.dart';

abstract class PressureRepository {
  Stream<PressureReading> stream = const Stream.empty();

  Future<void> init() async {}

  void dispose();
}
