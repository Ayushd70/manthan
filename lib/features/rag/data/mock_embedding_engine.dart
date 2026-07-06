import 'dart:convert';

import 'package:manthan/core/utils/vector_math.dart';
import 'package:manthan/data/local/entities.dart';
import 'package:manthan/features/inference/domain/embedding_engine.dart';

/// A deterministic, dependency-free embedding engine.
///
/// Produces stable hashed bag-of-words vectors. It is not semantically strong,
/// but it makes the full RAG pipeline (chunk -> embed -> index -> retrieve)
/// runnable and testable offline, and provides a graceful fallback before the
/// real EmbeddingGemma model is downloaded.
class MockEmbeddingEngine implements EmbeddingEngine {
  bool _loaded = false;

  @override
  bool get isLoaded => _loaded;

  @override
  int get dimensions => kEmbeddingDimensions;

  @override
  Future<void> load({
    required String modelPath,
    String? tokenizerPath,
    String? iosTokenizerPath,
  }) async {
    _loaded = true;
  }

  @override
  Future<List<double>> embedQuery(String text) async => _embed(text);

  @override
  Future<List<double>> embedDocument(String text) async => _embed(text);

  @override
  Future<void> dispose() async {
    _loaded = false;
  }

  List<double> _embed(String text) {
    final vector = List<double>.filled(dimensions, 0);
    final tokens = text
        .toLowerCase()
        .split(RegExp('[^a-z0-9]+'))
        .where((t) => t.isNotEmpty);
    for (final token in tokens) {
      final bucket =
          (utf8.encode(token).fold<int>(7, (h, b) => h * 31 + b) & 0x7fffffff) %
          dimensions;
      vector[bucket] += 1.0;
    }
    return VectorMath.normalize(vector);
  }
}
