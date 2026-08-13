import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manthan/core/providers.dart';
import 'package:manthan/data/local/secure_key_store.dart';
import 'package:manthan/features/settings/application/settings_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('SettingsController', () {
    late ProviderContainer container;
    late MemorySecureKeyStore secrets;

    setUp(() async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final prefs = await SharedPreferences.getInstance();
      secrets = MemorySecureKeyStore();
      container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          secureKeyStoreProvider.overrideWithValue(secrets),
        ],
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
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          secureKeyStoreProvider.overrideWithValue(MemorySecureKeyStore()),
        ],
      );
      addTearDown(loaded.dispose);

      expect(loaded.read(settingsProvider).hasCompletedOnboarding, isTrue);
    });

    test('stores Hugging Face token in secure storage', () async {
      await container
          .read(settingsProvider.notifier)
          .setHuggingFaceToken('hf_secret');

      expect(container.read(settingsProvider).huggingFaceToken, 'hf_secret');
      expect(await secrets.read('manthan.hfToken'), 'hf_secret');
      expect(
        container.read(sharedPreferencesProvider).getString('settings.hfToken'),
        isNull,
      );
    });

    test('migrates legacy prefs HF token into secure storage', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'settings.hfToken': 'hf_legacy',
      });
      final prefs = await SharedPreferences.getInstance();
      final store = MemorySecureKeyStore();
      final loaded = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          secureKeyStoreProvider.overrideWithValue(store),
        ],
      );
      addTearDown(loaded.dispose);

      loaded.read(settingsProvider);
      await pumpEventQueue();

      expect(loaded.read(settingsProvider).huggingFaceToken, 'hf_legacy');
      expect(await store.read('manthan.hfToken'), 'hf_legacy');
      expect(prefs.getString('settings.hfToken'), isNull);
    });

    test('persists whisper model id', () async {
      await container
          .read(settingsProvider.notifier)
          .setWhisperModelId('whisper-tiny');

      expect(container.read(settingsProvider).whisperModelId, 'whisper-tiny');
      expect(
        container
            .read(sharedPreferencesProvider)
            .getString(
              'settings.whisperModelId',
            ),
        'whisper-tiny',
      );
    });
  });
}
