import 'package:flutter_test/flutter_test.dart';
import 'package:manthan/core/utils/markdown_to_speech.dart';

void main() {
  group('MarkdownToSpeech', () {
    test('strips bold and headings', () {
      const input = '## Hello\n\nThis is **bold** text.';
      expect(
        MarkdownToSpeech.plainText(input),
        'Hello\n\nThis is bold text.',
      );
    });

    test('replaces fenced code with hint', () {
      const input = 'Here is code:\n\n```dart\nvoid main() {}\n```\n\nDone.';
      final out = MarkdownToSpeech.plainText(input);
      expect(out, contains('Code block omitted'));
      expect(out, contains('Done.'));
      expect(out, isNot(contains('void main')));
    });

    test('keeps link label text', () {
      const input = 'See [Manthan](https://example.com) for details.';
      expect(
        MarkdownToSpeech.plainText(input),
        'See Manthan for details.',
      );
    });
  });
}
