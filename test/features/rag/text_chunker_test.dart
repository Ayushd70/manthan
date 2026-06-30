import 'package:flutter_test/flutter_test.dart';
import 'package:manthan/features/rag/data/text_chunker.dart';

void main() {
  group('TextChunker', () {
    test('returns empty list for blank input', () {
      expect(const TextChunker().chunk('   '), isEmpty);
    });

    test('keeps short documents in a single chunk', () {
      final chunks = const TextChunker().chunk('Hello world.\n\nA short note.');
      expect(chunks, hasLength(1));
      expect(chunks.first, contains('Hello world'));
    });

    test('splits long documents into multiple chunks', () {
      final paragraph = List.generate(
        50,
        (i) => 'Sentence number $i.',
      ).join(' ');
      final text = List.filled(6, paragraph).join('\n\n');
      final chunks = const TextChunker(
        targetChars: 400,
        overlapChars: 50,
      ).chunk(text);
      expect(chunks.length, greaterThan(1));
    });

    test('splits an oversized single paragraph', () {
      final huge = 'a' * 5000;
      final chunks = const TextChunker(
        targetChars: 1000,
        overlapChars: 100,
      ).chunk(huge);
      expect(chunks.length, greaterThan(1));
    });
  });
}
