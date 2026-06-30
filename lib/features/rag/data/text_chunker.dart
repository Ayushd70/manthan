/// Splits long documents into overlapping chunks suitable for embedding.
///
/// Chunking happens on paragraph/sentence boundaries where possible so that
/// retrieved context stays coherent. Sizes are measured in characters as a
/// cheap proxy for tokens (roughly 4 chars/token).
class TextChunker {
  const TextChunker({this.targetChars = 1200, this.overlapChars = 200});

  /// Approximate target size of each chunk in characters.
  final int targetChars;

  /// Overlap between consecutive chunks to preserve context across boundaries.
  final int overlapChars;

  /// Splits [text] into chunks. Returns an empty list for blank input.
  List<String> chunk(String text) {
    final normalized = text.replaceAll('\r\n', '\n').trim();
    if (normalized.isEmpty) return const <String>[];

    final paragraphs = normalized
        .split(RegExp(r'\n\s*\n'))
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();

    final chunks = <String>[];
    final buffer = StringBuffer();

    void flush() {
      final value = buffer.toString().trim();
      if (value.isNotEmpty) chunks.add(value);
      buffer.clear();
    }

    for (final paragraph in paragraphs) {
      if (paragraph.length > targetChars) {
        flush();
        chunks.addAll(_splitLong(paragraph));
        continue;
      }
      if (buffer.length + paragraph.length + 2 > targetChars) {
        flush();
      }
      if (buffer.isNotEmpty) buffer.write('\n\n');
      buffer.write(paragraph);
    }
    flush();

    return _withOverlap(chunks);
  }

  List<String> _splitLong(String paragraph) {
    final out = <String>[];
    var start = 0;
    while (start < paragraph.length) {
      final end = (start + targetChars).clamp(0, paragraph.length);
      out.add(paragraph.substring(start, end).trim());
      if (end >= paragraph.length) break;
      start = end - overlapChars;
      if (start < 0) start = 0;
    }
    return out;
  }

  List<String> _withOverlap(List<String> chunks) {
    if (overlapChars <= 0 || chunks.length < 2) return chunks;
    final out = <String>[];
    for (var i = 0; i < chunks.length; i++) {
      if (i == 0) {
        out.add(chunks[i]);
        continue;
      }
      final prev = chunks[i - 1];
      final tail = prev.length <= overlapChars
          ? prev
          : prev.substring(prev.length - overlapChars);
      out.add('$tail\n\n${chunks[i]}');
    }
    return out;
  }
}
