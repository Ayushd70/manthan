import 'dart:typed_data';

import 'package:flutter_gemma/flutter_gemma.dart' as fg;
import 'package:manthan/features/chat/domain/chat_message.dart';
import 'package:manthan/features/inference/domain/engine_kind.dart';
import 'package:manthan/features/inference/domain/generation_config.dart';
import 'package:manthan/features/inference/domain/llm_engine.dart';

/// Production engine backed by Google's LiteRT-LM / MediaPipe runtime via the
/// `flutter_gemma` plugin. Handles `.task` and `.litertlm` model files and runs
/// inference off the UI thread through the plugin's native session.
class GemmaLlmEngine implements LlmEngine {
  GemmaLlmEngine({
    required this.displayName,
    required fg.ModelType modelType,
    required fg.ModelFileType fileType,
    this.supportsVision = false,
    this.isThinkingModel = false,
  }) : _modelType = modelType,
       _fileType = fileType;

  /// Label shown in the UI (engine + model).
  final String displayName;

  /// Whether the model can accept images.
  final bool supportsVision;

  /// Whether the model emits a separate "thinking" stream.
  final bool isThinkingModel;

  final fg.ModelType _modelType;
  final fg.ModelFileType _fileType;

  fg.InferenceModel? _model;
  fg.InferenceChat? _chat;
  fg.InferenceModelSession? _activeSession;
  bool _visionEnabled = false;

  @override
  EngineKind get kind => EngineKind.gemma;

  @override
  EngineCapabilities get capabilities => EngineCapabilities(
    kind: EngineKind.gemma,
    displayName: displayName,
    supportsImages: supportsVision,
  );

  @override
  bool get isLoaded => _chat != null;

  @override
  Future<void> load({
    required String modelPath,
    required GenerationConfig config,
    bool supportImage = false,
  }) async {
    try {
      _visionEnabled = supportImage && supportsVision;

      await fg.FlutterGemma.installModel(
        modelType: _modelType,
        fileType: _fileType,
      ).fromFile(modelPath).install();

      final model = await fg.FlutterGemma.getActiveModel(
        maxTokens: config.maxTokens,
        supportImage: _visionEnabled,
      );
      _model = model;

      _chat = await model.createChat(
        temperature: config.temperature,
        topK: config.topK,
        topP: config.topP,
        supportImage: _visionEnabled,
        modelType: _modelType,
        isThinking: isThinkingModel,
        systemInstruction: config.systemPrompt,
      );
    } on Object catch (e) {
      throw EngineException('Failed to load Gemma model', e);
    }
  }

  @override
  Stream<GenerationChunk> generate(
    List<ChatMessage> history, {
    List<Uint8List> images = const <Uint8List>[],
  }) async* {
    final chat = _chat;
    if (chat == null) {
      throw const EngineException('Gemma engine has no model loaded');
    }
    if (history.isEmpty) return;

    final latest = history.last;
    final message = (_visionEnabled && images.isNotEmpty)
        ? fg.Message(text: latest.text, isUser: true, imageBytes: images.first)
        : fg.Message.text(text: latest.text, isUser: true);

    await chat.addQueryChunk(message);

    await for (final response in chat.generateChatResponseAsync()) {
      switch (response) {
        case fg.TextResponse(:final token):
          yield GenerationChunk(textDelta: token);
        case fg.ThinkingResponse(:final content):
          yield GenerationChunk(textDelta: content, isThinking: true);
        case fg.FunctionCallResponse():
        case fg.ParallelFunctionCallResponse():
          break;
      }
    }
  }

  @override
  Future<void> stop() async {
    await _activeSession?.stopGeneration();
    await _chat?.session.stopGeneration();
  }

  @override
  Future<void> dispose() async {
    await _chat?.session.close();
    await _model?.close();
    _chat = null;
    _model = null;
    _activeSession = null;
  }
}
