import 'dart:typed_data';

import 'package:manthan/features/chat/domain/chat_message.dart';
import 'package:manthan/features/inference/domain/engine_kind.dart';
import 'package:manthan/features/inference/domain/generation_config.dart';

/// A single streamed unit of generation output.
class GenerationChunk {
  const GenerationChunk({
    required this.textDelta,
    this.isThinking = false,
  });

  /// Newly produced text since the previous chunk.
  final String textDelta;

  /// True when the model is emitting "thinking" content (reasoning models).
  final bool isThinking;
}

/// Static description of what an engine/model can do, surfaced to the UI.
class EngineCapabilities {
  const EngineCapabilities({
    required this.kind,
    required this.displayName,
    this.supportsImages = false,
    this.supportsEmbeddings = false,
    this.supportsStreaming = true,
  });

  /// The backing runtime.
  final EngineKind kind;

  /// Human-readable engine + model label.
  final String displayName;

  /// Whether image inputs are accepted (multimodal).
  final bool supportsImages;

  /// Whether the engine can produce embedding vectors for RAG.
  final bool supportsEmbeddings;

  /// Whether tokens are streamed incrementally.
  final bool supportsStreaming;
}

/// Thrown when an engine operation fails (load or generation).
class EngineException implements Exception {
  const EngineException(this.message, [this.cause]);

  /// Human-readable description.
  final String message;

  /// Underlying error, if any.
  final Object? cause;

  @override
  String toString() =>
      'EngineException: $message${cause != null ? ' ($cause)' : ''}';
}

/// The single abstraction every inference runtime implements.
///
/// This is the seam that lets Manthan ship multiple backends (mock, Gemma,
/// llama.cpp) behind one contract. The UI and controllers depend only on this
/// interface, never on a concrete runtime.
abstract interface class LlmEngine {
  /// The backing runtime kind.
  EngineKind get kind;

  /// Capabilities of the currently loaded model.
  EngineCapabilities get capabilities;

  /// Whether a model is loaded and ready to generate.
  bool get isLoaded;

  /// Loads the model located at [modelPath] applying [config].
  ///
  /// [supportImage] requests multimodal vision support when the model allows.
  /// For the mock engine [modelPath] is ignored.
  Future<void> load({
    required String modelPath,
    required GenerationConfig config,
    bool supportImage = false,
  });

  /// Streams the assistant response for the given [history].
  ///
  /// The last entry in [history] is the newest user turn. [images] are optional
  /// image bytes attached to that turn for multimodal models.
  Stream<GenerationChunk> generate(
    List<ChatMessage> history, {
    List<Uint8List> images = const <Uint8List>[],
  });

  /// Requests the current generation to stop early.
  Future<void> stop();

  /// Releases all native resources held by the engine.
  Future<void> dispose();
}
