import 'package:espresso_log/domain/bean/dose.dart';
import 'package:espresso_log/domain/settings/settings_repository.dart';

/// In-memory [SettingsRepository] for tests.
class FakeSettings implements SettingsRepository {
  @override
  int startDelayCompensationSeconds = 0;

  @override
  ScaleSource scaleSource = ScaleSource.mock;

  @override
  PressureSource pressureSource = PressureSource.mock;

  @override
  String? selectedBeanId;

  @override
  double unknownBeanDoseGrams = defaultDoseGrams;

  @override
  Future<void> setStartDelayCompensationSeconds(int seconds) async =>
      startDelayCompensationSeconds = seconds;

  @override
  Future<void> setScaleSource(ScaleSource source) async => scaleSource = source;

  @override
  Future<void> setPressureSource(PressureSource source) async =>
      pressureSource = source;

  @override
  Future<void> setSelectedBeanId(String? id) async => selectedBeanId = id;

  @override
  Future<void> setUnknownBeanDoseGrams(double grams) async =>
      unknownBeanDoseGrams = grams;
}
