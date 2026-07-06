import 'package:manthan/features/inference/domain/embedding_engine.dart';
import 'package:manthan/features/rag/data/gemma_embedding_engine.dart';
import 'package:manthan/features/rag/data/mock_embedding_engine.dart';

/// Creates concrete [EmbeddingEngine] implementations.
abstract final class EmbeddingFactory {
  /// Deterministic offline embedder (no downloads).
  static EmbeddingEngine mock() => MockEmbeddingEngine();

  /// EmbeddingGemma via `flutter_gemma`.
  static EmbeddingEngine gemma() => GemmaEmbeddingEngine();
}
