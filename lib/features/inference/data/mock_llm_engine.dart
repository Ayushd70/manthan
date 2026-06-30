import 'dart:async';
import 'dart:typed_data';

import 'package:manthan/features/chat/domain/chat_message.dart';
import 'package:manthan/features/inference/domain/engine_kind.dart';
import 'package:manthan/features/inference/domain/generation_config.dart';
import 'package:manthan/features/inference/domain/llm_engine.dart';

/// A dependency-free engine that simulates streaming generation.
///
/// It exists for three reasons:
/// 1. The app is fully usable on first launch before any model is downloaded.
/// 2. CI / unit / widget tests can exercise the entire chat pipeline without
///    shipping multi-gigabyte weights or native inference libraries.
/// 3. It documents the [LlmEngine] contract with a trivial reference impl.
class MockLlmEngine implements LlmEngine {
  MockLlmEngine({this.tokenDelay = const Duration(milliseconds: 18)});

  /// Delay between emitted tokens, simulating decode latency.
  final Duration tokenDelay;

  bool _loaded = false;
  bool _cancelled = false;

  @override
  EngineKind get kind => EngineKind.mock;

  @override
  EngineCapabilities get capabilities => const EngineCapabilities(
    kind: EngineKind.mock,
    displayName: 'Built-in demo model',
    supportsImages: true,
  );

  @override
  bool get isLoaded => _loaded;

  @override
  Future<void> load({
    required String modelPath,
    required GenerationConfig config,
    bool supportImage = false,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    _loaded = true;
  }

  @override
  Stream<GenerationChunk> generate(
    List<ChatMessage> history, {
    List<Uint8List> images = const <Uint8List>[],
  }) async* {
    _cancelled = false;
    final lastUser = history.lastWhere(
      (m) => m.role == ChatRole.user,
      orElse: () => history.isNotEmpty
          ? history.last
          : ChatMessage(
              id: 'x',
              role: ChatRole.user,
              text: '',
              createdAt: DateTime.now(),
            ),
    );

    final reply = _composeReply(lastUser.text, hasImage: images.isNotEmpty);
    final tokens = _tokenize(reply);
    for (final token in tokens) {
      if (_cancelled) return;
      await Future<void>.delayed(tokenDelay);
      yield GenerationChunk(textDelta: token);
    }
  }

  @override
  Future<void> stop() async {
    _cancelled = true;
  }

  @override
  Future<void> dispose() async {
    _loaded = false;
  }

  /// Splits text into streaming-friendly chunks that keep whitespace attached.
  static List<String> _tokenize(String text) {
    final regex = RegExp(r'\S+\s*');
    return regex.allMatches(text).map((m) => m.group(0)!).toList();
  }

  String _composeReply(String prompt, {required bool hasImage}) {
    final p = prompt.toLowerCase().trim();

    if (hasImage) {
      return "I can see the image you attached. Running on-device, I'd "
          'describe its contents, read any text, and answer questions about '
          'it — all without uploading the photo anywhere.\n\n'
          '> This is the built-in demo engine. Download a vision model from '
          'the **Models** tab to analyze real images.';
    }
    if (p.isEmpty) {
      return 'Hi! Ask me anything.';
    }
    if (p.contains('hello') || p.contains('hi') || p.contains('hey')) {
      return "Hello! I'm **Manthan**, a fully on-device AI assistant. "
          'Nothing you type leaves your device.\n\n'
          'Try asking me to explain a concept, or download a real model from '
          'the **Models** tab to unlock full capabilities.';
    }
    if (p.contains('code') ||
        p.contains('dart') ||
        p.contains('flutter') ||
        p.contains('function')) {
      return "Sure — here's a small Dart example:\n\n"
          '```dart\n'
          'String greet(String name) => "Hello, \$name!";\n\n'
          'void main() => print(greet("Manthan"));\n'
          '```\n\n'
          'The chat renders **markdown** and syntax-highlighted code blocks. '
          'A downloaded model would produce real answers here.';
    }
    if (p.contains('how are you')) {
      return "I'm running locally and feeling fast. How can I help?";
    }
    if (p.contains('privacy') ||
        p.contains('offline') ||
        p.contains('secure')) {
      return '### Privacy by design\n\n'
          'Manthan performs **all** inference on-device:\n\n'
          '- No network calls during chat\n'
          '- No telemetry or analytics\n'
          '- Your conversations and documents never leave the device\n\n'
          'You can verify this by enabling airplane mode — everything keeps '
          'working.';
    }
    return 'You said: "$prompt".\n\n'
        "This is Manthan's built-in demo engine, so the reply is simulated. "
        'Head to the **Models** tab to download a real on-device LLM '
        '(Gemma via LiteRT-LM, or any GGUF via llama.cpp) and switch engines '
        'in **Settings** to get genuine answers — fully offline.';
  }
}
