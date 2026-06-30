import 'package:flutter_test/flutter_test.dart';
import 'package:manthan/core/utils/vector_math.dart';

void main() {
  group('VectorMath.cosineSimilarity', () {
    test('identical vectors score 1', () {
      final v = <double>[1, 2, 3];
      expect(VectorMath.cosineSimilarity(v, v), closeTo(1, 1e-9));
    });

    test('orthogonal vectors score 0', () {
      expect(
        VectorMath.cosineSimilarity(<double>[1, 0], <double>[0, 1]),
        closeTo(0, 1e-9),
      );
    });

    test('opposite vectors score -1', () {
      expect(
        VectorMath.cosineSimilarity(<double>[1, 0], <double>[-1, 0]),
        closeTo(-1, 1e-9),
      );
    });

    test('zero vector yields 0', () {
      expect(
        VectorMath.cosineSimilarity(<double>[0, 0], <double>[1, 1]),
        0,
      );
    });
  });

  group('VectorMath.normalize', () {
    test('produces a unit vector', () {
      final n = VectorMath.normalize(<double>[3, 4]);
      final magnitude = VectorMath.cosineSimilarity(n, n);
      expect(magnitude, closeTo(1, 1e-9));
      expect(n[0], closeTo(0.6, 1e-9));
      expect(n[1], closeTo(0.8, 1e-9));
    });
  });
}
