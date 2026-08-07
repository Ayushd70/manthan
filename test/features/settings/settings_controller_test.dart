import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manthan/core/providers.dart';
import 'package:manthan/features/settings/application/settings_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('SettingsController onboarding', () {
    late ProviderContainer container;

    setUp(() async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final prefs = await SharedPreferences.getInstance();
      container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
    });

    tearDown(() => container.dispose());

    test('defaults hasCompletedOnboarding to false', () {
      expect(container.read(settingsProvider).hasCompletedOnboarding, isFalse);
    });

    test('completeOnboarding persists the flag', () async {
      await container.read(settingsProvider.notifier).completeOnboarding();

      expect(container.read(settingsProvider).hasCompletedOnboarding, isTrue);

      final prefs = container.read(sharedPreferencesProvider);
      expect(prefs.getBool('settings.hasCompletedOnboarding'), isTrue);
    });

    test('loads completed onboarding from prefs', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'settings.hasCompletedOnboarding': true,
      });
      final prefs = await SharedPreferences.getInstance();
      final loaded = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(loaded.dispose);

      expect(loaded.read(settingsProvider).hasCompletedOnboarding, isTrue);
    });
  });
}
