import 'package:manthan/features/inference/domain/llm_engine.dart'
    show LlmEngine;

/// Produces dense vector embeddings for text, used by the RAG pipeline.
///
/// Kept separate from [LlmEngine] because embedding and generation models are
/// usually distinct artifacts with different lifecycles.
abstract interface class EmbeddingEngine {
  /// Whether an embedding model is loaded.
  bool get isLoaded;

  /// Dimensionality of produced vectors (e.g. 768 for EmbeddingGemma).
  int get dimensions;

  /// Loads the embedding model at [modelPath] (+ optional tokenizer paths).
  Future<void> load({
    required String modelPath,
    String? tokenizerPath,
    String? iosTokenizerPath,
  });

  /// Embeds a search query (some models prefix queries differently).
  Future<List<double>> embedQuery(String text);

  /// Embeds a document/passage for indexing.
  Future<List<double>> embedDocument(String text);

  /// Releases native resources.
  Future<void> dispose();
}
