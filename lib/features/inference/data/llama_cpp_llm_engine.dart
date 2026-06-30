import 'dart:async';
import 'dart:typed_data';

import 'package:llama_cpp_dart/llama_cpp_dart.dart' as llama;
import 'package:manthan/features/chat/domain/chat_message.dart';
import 'package:manthan/features/inference/domain/engine_kind.dart';
import 'package:manthan/features/inference/domain/generation_config.dart';
import 'package:manthan/features/inference/domain/llm_engine.dart';

/// Production engine backed by `llama.cpp` (via `llama_cpp_dart`) for GGUF
/// models. Inference runs in a dedicated worker isolate so the UI thread never
/// blocks, with NPU/Metal/OpenCL acceleration where the native build supports
/// it.
class LlamaCppLlmEngine implements LlmEngine {
  LlamaCppLlmEngine({
    required this.displayName,
    this.promptFormat,
    this.libraryPath,
  });

  /// Label shown in the UI (engine + model).
  final String displayName;

  /// Chat template formatter; defaults to ChatML which suits most GGUF chats.
  final llama.PromptFormat? promptFormat;

  /// Optional explicit path to the native `llama` shared library (desktop).
  final String? libraryPath;

  llama.LlamaParent? _parent;

  @override
  EngineKind get kind => EngineKind.llamaCpp;

  @override
  EngineCapabilities get capabilities => EngineCapabilities(
    kind: EngineKind.llamaCpp,
    displayName: displayName,
  );

  @override
  bool get isLoaded => _parent != null;

  @override
  Future<void> load({
    required String modelPath,
    required GenerationConfig config,
    bool supportImage = false,
  }) async {
    try {
      if (libraryPath != null) {
        llama.Llama.libraryPath = libraryPath;
      }

      final contextParams = llama.ContextParams()
        ..nCtx = config.maxTokens
        ..nPredict = config.maxTokens;

      final samplerParams = llama.SamplerParams()
        ..temp = config.temperature
        ..topK = config.topK
        ..topP = config.topP;
      if (config.randomSeed != null) {
        samplerParams.seed = config.randomSeed!;
      }

      final loadCommand = llama.LlamaLoad(
        path: modelPath,
        modelParams: llama.ModelParams(),
        contextParams: contextParams,
        samplingParams: samplerParams,
      );

      final parent = llama.LlamaParent(
        loadCommand,
        promptFormat ?? llama.ChatMLFormat(),
      );
      await parent.init();
      _parent = parent;
    } on Object catch (e) {
      throw EngineException('Failed to load GGUF model', e);
    }
  }

  @override
  Stream<GenerationChunk> generate(
    List<ChatMessage> history, {
    List<Uint8List> images = const <Uint8List>[],
  }) {
    final parent = _parent;
    if (parent == null) {
      throw const EngineException('llama.cpp engine has no model loaded');
    }
    if (history.isEmpty) return const Stream<GenerationChunk>.empty();

    final controller = StreamController<GenerationChunk>();
    parent.messages = _toMessages(history);

    String? promptId;
    late final StreamSubscription<String> tokenSub;
    late final StreamSubscription<llama.CompletionEvent> doneSub;

    Future<void> cleanup() async {
      await tokenSub.cancel();
      await doneSub.cancel();
    }

    tokenSub = parent.stream.listen(
      (token) => controller.add(GenerationChunk(textDelta: token)),
    );
    doneSub = parent.completions.listen((event) async {
      if (promptId != null && event.promptId != promptId) return;
      await cleanup();
      if (!event.success && !controller.isClosed) {
        controller.addError(
          EngineException(event.errorDetails ?? 'Generation failed'),
        );
      }
      if (!controller.isClosed) await controller.close();
    });

    unawaited(
      parent.sendPrompt(history.last.text).then((id) => promptId = id),
    );

    controller.onCancel = () async {
      await parent.stop();
      await cleanup();
    };

    return controller.stream;
  }

  @override
  Future<void> stop() async {
    await _parent?.stop();
  }

  @override
  Future<void> dispose() async {
    await _parent?.dispose();
    _parent = null;
  }

  List<Map<String, dynamic>> _toMessages(List<ChatMessage> history) {
    return <Map<String, dynamic>>[
      for (final m in history)
        if (m.role != ChatRole.system)
          <String, dynamic>{
            'role': m.role == ChatRole.user ? 'user' : 'assistant',
            'content': m.text,
          },
    ];
  }
}
