import 'package:flutter_test/flutter_test.dart';
import 'package:manthan/core/utils/vector_math.dart';
import 'package:manthan/data/local/entities.dart';
import 'package:manthan/features/rag/data/mock_embedding_engine.dart';

void main() {
  group('MockEmbeddingEngine', () {
    late MockEmbeddingEngine engine;

    setUp(() async {
      engine = MockEmbeddingEngine();
      await engine.load(modelPath: '');
    });

    test('produces vectors of the configured dimensionality', () async {
      final v = await engine.embedDocument('the quick brown fox');
      expect(v, hasLength(kEmbeddingDimensions));
    });

    test('is deterministic for identical text', () async {
      final a = await engine.embedQuery('on-device privacy');
      final b = await engine.embedQuery('on-device privacy');
      expect(VectorMath.cosineSimilarity(a, b), closeTo(1, 1e-9));
    });

    test('similar text scores higher than unrelated text', () async {
      final query = await engine.embedQuery('flutter mobile development');
      final related = await engine.embedDocument(
        'mobile development with flutter',
      );
      final unrelated = await engine.embedDocument(
        'photosynthesis in green plants',
      );
      expect(
        VectorMath.cosineSimilarity(query, related),
        greaterThan(VectorMath.cosineSimilarity(query, unrelated)),
      );
    });
  });
}
