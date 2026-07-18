import 'package:flutter_test/flutter_test.dart';
import 'package:manthan/features/inference/domain/generation_config.dart';

void main() {
  group('GenerationConfig', () {
    test('round-trips through JSON', () {
      const config = GenerationConfig(
        temperature: 0.5,
        topK: 20,
        topP: 0.9,
        maxTokens: 2048,
        systemPrompt: 'Be concise.',
        randomSeed: 7,
      );

      final restored = GenerationConfig.fromJson(config.toJson());

      expect(restored, config);
    });

    test('fromJson falls back to defaults for missing fields', () {
      final restored = GenerationConfig.fromJson(const <String, Object?>{});

      expect(restored, const GenerationConfig());
    });

    test('fromJson tolerates null systemPrompt and randomSeed', () {
      final restored = GenerationConfig.fromJson(const <String, Object?>{
        'temperature': 1.0,
        'topK': 10,
        'topP': 0.5,
        'maxTokens': 512,
        'systemPrompt': null,
        'randomSeed': null,
      });

      expect(restored.systemPrompt, isNull);
      expect(restored.randomSeed, isNull);
      expect(restored.temperature, 1.0);
    });
  });
}
