import 'package:espresso_log/domain/settings/settings_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesSettingsService implements SettingsRepository {
  static const _startDelayCompensationKey = 'startDelayCompensationSeconds';

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
}
