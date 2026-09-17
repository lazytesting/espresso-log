import 'package:espresso_log/domain/telemetry/scale_event.dart';

abstract class ScaleRepository {
  Stream<ScaleEvent> stream = const Stream.empty();

  Future<void> init() async {}

  Future<void> tareCommand() async {}
}
