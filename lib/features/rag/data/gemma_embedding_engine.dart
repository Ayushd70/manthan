import 'package:flutter_gemma/flutter_gemma.dart' as fg;
import 'package:manthan/features/inference/domain/embedding_engine.dart';

/// Real on-device embedding engine backed by EmbeddingGemma via `flutter_gemma`.
class GemmaEmbeddingEngine implements EmbeddingEngine {
  fg.EmbeddingModel? _model;
  int _dimensions = 768;

  @override
  bool get isLoaded => _model != null;

  @override
  int get dimensions => _dimensions;

  @override
  Future<void> load({
    required String modelPath,
    String? tokenizerPath,
    String? iosTokenizerPath,
  }) async {
    await fg.FlutterGemma.installEmbedder()
        .modelFromFile(modelPath)
        .tokenizerFromFile(
          tokenizerPath ?? iosTokenizerPath ?? modelPath,
          iosPath: iosTokenizerPath,
        )
        .install();
    final model = await fg.FlutterGemma.getActiveEmbedder();
    _model = model;
    _dimensions = await model.getDimension();
  }

  @override
  Future<List<double>> embedQuery(String text) async {
    final model = _model;
    if (model == null) throw StateError('Embedding model not loaded');
    return model.generateEmbedding(text);
  }

  @override
  Future<List<double>> embedDocument(String text) async {
    final model = _model;
    if (model == null) throw StateError('Embedding model not loaded');
    return model.generateEmbedding(
      text,
      taskType: fg.TaskType.retrievalDocument,
    );
  }

  @override
  Future<void> dispose() async {
    await _model?.close();
    _model = null;
  }
}
