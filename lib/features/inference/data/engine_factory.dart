import 'package:flutter_gemma/flutter_gemma.dart' as fg;
import 'package:llama_cpp_dart/llama_cpp_dart.dart' as llama;
import 'package:manthan/features/inference/data/gemma_llm_engine.dart';
import 'package:manthan/features/inference/data/llama_cpp_llm_engine.dart';
import 'package:manthan/features/inference/data/mock_llm_engine.dart';
import 'package:manthan/features/inference/domain/engine_kind.dart';
import 'package:manthan/features/inference/domain/llm_engine.dart';
import 'package:manthan/features/models/domain/model_info.dart';

/// Creates the concrete [LlmEngine] for a given [ModelInfo].
///
/// This is the only place that maps domain model metadata onto vendor-specific
/// runtime types, keeping the rest of the app vendor-agnostic.
abstract final class EngineFactory {
  /// Builds an engine for [model]. For [EngineKind.mock] the model is ignored.
  static LlmEngine create(ModelInfo model) {
    switch (model.engineKind) {
      case EngineKind.mock:
        return MockLlmEngine();
      case EngineKind.gemma:
        return GemmaLlmEngine(
          displayName: model.name,
          modelType: _gemmaType(model.family),
          fileType: _fileType(model.fileFormat),
          supportsVision: model.supportsVision,
          isThinkingModel: model.isThinkingModel,
        );
      case EngineKind.llamaCpp:
        return LlamaCppLlmEngine(
          displayName: model.name,
          promptFormat: _promptFormat(model.family),
        );
    }
  }

  /// The always-available built-in engine.
  static LlmEngine mock() => MockLlmEngine();

  static fg.ModelType _gemmaType(GemmaModelFamily family) {
    return switch (family) {
      GemmaModelFamily.gemmaIt => fg.ModelType.gemmaIt,
      GemmaModelFamily.deepSeek => fg.ModelType.deepSeek,
      GemmaModelFamily.qwen => fg.ModelType.qwen,
      GemmaModelFamily.qwen3 => fg.ModelType.qwen3,
      GemmaModelFamily.llama => fg.ModelType.llama,
      GemmaModelFamily.phi => fg.ModelType.phi,
      GemmaModelFamily.general => fg.ModelType.general,
    };
  }

  static fg.ModelFileType _fileType(ModelFileFormat format) {
    return switch (format) {
      ModelFileFormat.task => fg.ModelFileType.task,
      ModelFileFormat.litertlm => fg.ModelFileType.litertlm,
      ModelFileFormat.binary => fg.ModelFileType.binary,
      ModelFileFormat.gguf => fg.ModelFileType.binary,
    };
  }

  static llama.PromptFormat _promptFormat(GemmaModelFamily family) {
    return switch (family) {
      GemmaModelFamily.gemmaIt => llama.GemmaFormat(),
      _ => llama.ChatMLFormat(),
    };
  }
}
