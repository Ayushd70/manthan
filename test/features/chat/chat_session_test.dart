import 'package:flutter_test/flutter_test.dart';
import 'package:manthan/features/chat/domain/chat_session.dart';
import 'package:manthan/features/inference/domain/generation_config.dart';

void main() {
  ChatSession session() {
    final now = DateTime(2026);
    return ChatSession(id: 's1', title: 'Chat', createdAt: now, updatedAt: now);
  }

  group('ChatSession', () {
    test('has no custom engine settings by default', () {
      expect(session().hasCustomEngineSettings, isFalse);
    });

    test('pinning a model marks custom engine settings', () {
      final pinned = session().copyWith(modelId: () => 'model-a');

      expect(pinned.modelId, 'model-a');
      expect(pinned.hasCustomEngineSettings, isTrue);
    });

    test('setting generation overrides marks custom engine settings', () {
      final overridden = session().copyWith(
        generationOverrides: () => const GenerationConfig(temperature: 0.2),
      );

      expect(overridden.generationOverrides?.temperature, 0.2);
      expect(overridden.hasCustomEngineSettings, isTrue);
    });

    test('copyWith(modelId: () => null) clears a pinned model', () {
      final pinned = session().copyWith(modelId: () => 'model-a');
      final cleared = pinned.copyWith(modelId: () => null);

      expect(cleared.modelId, isNull);
      expect(cleared.hasCustomEngineSettings, isFalse);
    });
  });
}
