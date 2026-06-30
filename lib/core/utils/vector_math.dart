import 'dart:math' as math;

/// Pure vector helpers for embeddings / semantic search.
///
/// ObjectBox performs the heavy nearest-neighbour search natively via its HNSW
/// index, but these helpers are used for re-ranking, tests, and any platform
/// that falls back to brute-force search.
abstract final class VectorMath {
  /// Cosine similarity between two equally sized vectors in `[-1, 1]`.
  static double cosineSimilarity(List<double> a, List<double> b) {
    assert(a.length == b.length, 'Vectors must share dimensionality');
    if (a.isEmpty) return 0;
    var dot = 0.0;
    var normA = 0.0;
    var normB = 0.0;
    for (var i = 0; i < a.length; i++) {
      dot += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }
    final denom = math.sqrt(normA) * math.sqrt(normB);
    if (denom == 0) return 0;
    return dot / denom;
  }

  /// Returns an L2-normalised copy of [v] (unit length).
  static List<double> normalize(List<double> v) {
    var norm = 0.0;
    for (final x in v) {
      norm += x * x;
    }
    norm = math.sqrt(norm);
    if (norm == 0) return List<double>.filled(v.length, 0);
    return <double>[for (final x in v) x / norm];
  }
}
