import 'package:flutter_test/flutter_test.dart';
import 'package:manthan/features/chat/domain/chat_message.dart';
import 'package:manthan/features/inference/data/mock_llm_engine.dart';
import 'package:manthan/features/inference/domain/engine_kind.dart';
import 'package:manthan/features/inference/domain/generation_config.dart';

ChatMessage _user(String text) => ChatMessage(
  id: 't',
  role: ChatRole.user,
  text: text,
  createdAt: DateTime(2026),
);

void main() {
  group('MockLlmEngine', () {
    late MockLlmEngine engine;

    setUp(() {
      engine = MockLlmEngine(tokenDelay: Duration.zero);
    });

    test('reports mock kind and loads', () async {
      expect(engine.kind, EngineKind.mock);
      expect(engine.isLoaded, isFalse);
      await engine.load(modelPath: '', config: const GenerationConfig());
      expect(engine.isLoaded, isTrue);
    });

    test('streams a non-empty response assembled from deltas', () async {
      await engine.load(modelPath: '', config: const GenerationConfig());
      final buffer = StringBuffer();
      await for (final chunk in engine.generate(<ChatMessage>[
        _user('hello'),
      ])) {
        buffer.write(chunk.textDelta);
      }
      expect(buffer.toString(), isNotEmpty);
      expect(buffer.toString().toLowerCase(), contains('manthan'));
    });

    test('stop halts the stream early', () async {
      final engineSlow = MockLlmEngine(
        tokenDelay: const Duration(milliseconds: 50),
      );
      await engineSlow.load(modelPath: '', config: const GenerationConfig());
      final received = <String>[];
      final sub = engineSlow
          .generate(<ChatMessage>[_user('tell me about privacy')])
          .listen((chunk) => received.add(chunk.textDelta));
      await Future<void>.delayed(const Duration(milliseconds: 60));
      await engineSlow.stop();
      await sub.cancel();
      expect(received.length, greaterThanOrEqualTo(0));
    });

    test('emits a calculator tool call for arithmetic prompts', () async {
      await engine.load(modelPath: '', config: const GenerationConfig());
      final buffer = StringBuffer();
      await for (final chunk in engine.generate(<ChatMessage>[
        _user('what is 12 * 7'),
      ])) {
        buffer.write(chunk.textDelta);
      }
      expect(buffer.toString(), contains('<tool_call>'));
      expect(buffer.toString(), contains('calculator'));
      expect(buffer.toString(), contains('12*7'));
    });

    test('answers from a tool result follow-up', () async {
      await engine.load(modelPath: '', config: const GenerationConfig());
      final buffer = StringBuffer();
      await for (final chunk in engine.generate(<ChatMessage>[
        _user('what is 2+2'),
        ChatMessage(
          id: 'a',
          role: ChatRole.assistant,
          text: '<tool_call>{"name":"calculator"}</tool_call>',
          createdAt: DateTime(2026),
        ),
        _user('Tool result (calculator): 4'),
      ])) {
        buffer.write(chunk.textDelta);
      }
      expect(buffer.toString(), contains('4'));
    });
  });
}
