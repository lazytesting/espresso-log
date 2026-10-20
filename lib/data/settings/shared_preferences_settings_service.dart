import 'package:espresso_log/domain/settings/settings_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesSettingsService implements SettingsRepository {
  static const _startDelayCompensationKey = 'startDelayCompensationSeconds';

  static const _scaleSourceKey = 'scaleSource';
  static const _pressureSourceKey = 'pressureSource';

  final SharedPreferences _prefs;

  SharedPreferencesSettingsService._(this._prefs);

  static Future<SharedPreferencesSettingsService> create() async =>
      SharedPreferencesSettingsService._(await SharedPreferences.getInstance());

  @override
  int get startDelayCompensationSeconds =>
      (_prefs.getInt(_startDelayCompensationKey) ?? 0).clamp(
        SettingsRepository.minStartDelayCompensationSeconds,
        SettingsRepository.maxStartDelayCompensationSeconds,
      );

  @override
  Future<void> setStartDelayCompensationSeconds(int seconds) async {
    await _prefs.setInt(_startDelayCompensationKey, seconds);
  }

  @override
  ScaleSource get scaleSource => ScaleSource.values.firstWhere(
    (s) => s.name == _prefs.getString(_scaleSourceKey),
    orElse: () => ScaleSource.decent,
  );

  @override
  Future<void> setScaleSource(ScaleSource source) async {
    await _prefs.setString(_scaleSourceKey, source.name);
  }

  @override
  PressureSource get pressureSource => PressureSource.values.firstWhere(
    (s) => s.name == _prefs.getString(_pressureSourceKey),
    orElse: () => PressureSource.bookoo,
  );

  @override
  Future<void> setPressureSource(PressureSource source) async {
    await _prefs.setString(_pressureSourceKey, source.name);
  }
}
