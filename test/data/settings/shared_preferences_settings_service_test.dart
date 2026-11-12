import 'package:espresso_log/data/settings/shared_preferences_settings_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Future<SharedPreferencesSettingsService> create([
    Map<String, Object> initial = const {},
  ]) async {
    SharedPreferences.setMockInitialValues(initial);
    return SharedPreferencesSettingsService.create();
  }

  group('selectedBeanId', () {
    test('is null by default', () async {
      final settings = await create();
      expect(settings.selectedBeanId, isNull);
    });

    test('round-trips a value', () async {
      final settings = await create();
      await settings.setSelectedBeanId('abc');
      expect(settings.selectedBeanId, 'abc');
    });

    test('is null again after setting null', () async {
      final settings = await create();
      await settings.setSelectedBeanId('abc');
      await settings.setSelectedBeanId(null);
      expect(settings.selectedBeanId, isNull);
    });
  });

  group('unknownBeanDoseGrams', () {
    test('defaults to 18.0', () async {
      final settings = await create();
      expect(settings.unknownBeanDoseGrams, 18.0);
    });

    test('round-trips a value', () async {
      final settings = await create();
      await settings.setUnknownBeanDoseGrams(17.5);
      expect(settings.unknownBeanDoseGrams, 17.5);
    });

    test('normalizes an out-of-range stored value on read', () async {
      final settings = await create({'unknownBeanDoseGrams': 99.0});
      expect(settings.unknownBeanDoseGrams, 30.0);
    });
  });
}
