import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manthan/features/inference/application/engine_controller.dart';
import 'package:manthan/features/inference/domain/generation_config.dart';
import 'package:manthan/features/settings/application/settings_controller.dart';
import 'package:manthan/features/settings/domain/app_settings.dart';

class _FakeSettingsController extends SettingsController {
  @override
  AppSettings build() => const AppSettings();
}

void main() {
  group('EngineController', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer(
        overrides: [settingsProvider.overrideWith(_FakeSettingsController.new)],
      );
      // Let the build()-triggered microtask activation settle before each test.
      addTearDown(container.dispose);
    });

    test(
      'activate falls back to the global generation config by default',
      () async {
        final notifier = container.read(engineControllerProvider.notifier);
        // Let the build()-triggered startup activation settle first so it
        // doesn't race with the explicit call below.
        await pumpEventQueue();

        await notifier.activate(null);

        final state = container.read(engineControllerProvider);
        expect(state.activeConfig, const GenerationConfig());
      },
    );

    test(
      'activate prefers an explicit configOverride over global settings',
      () async {
        final notifier = container.read(engineControllerProvider.notifier);
        await pumpEventQueue();

        const override = GenerationConfig(
          temperature: 0.1,
          systemPrompt: 'Pinned.',
        );

        await notifier.activate(null, configOverride: override);

        final state = container.read(engineControllerProvider);
        expect(state.activeConfig, override);
      },
    );
  });
}
