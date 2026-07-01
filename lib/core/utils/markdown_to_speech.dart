/// Strips common Markdown syntax so assistant replies can be read aloud.
abstract final class MarkdownToSpeech {
  /// Returns plain text suitable for TTS from a Markdown [source].
  static String plainText(String source) {
    if (source.trim().isEmpty) return '';

    var text = source;

    // Fenced code blocks → skip body, keep a short hint.
    text = text.replaceAllMapped(
      RegExp(r'```[\w]*\n([\s\S]*?)```'),
      (m) => m.group(1)!.trim().isEmpty ? '' : 'Code block omitted. ',
    );

    // Inline code.
    text = text.replaceAllMapped(
      RegExp('`([^`]+)`'),
      (m) => m.group(1) ?? '',
    );

    // Images and links: keep label text.
    text = text.replaceAllMapped(
      RegExp(r'!\[([^\]]*)\]\([^)]*\)'),
      (m) => m.group(1) ?? '',
    );
    text = text.replaceAllMapped(
      RegExp(r'\[([^\]]+)\]\([^)]*\)'),
      (m) => m.group(1) ?? '',
    );

    // Headings, bold, italic, strike.
    text = text.replaceAll(RegExp(r'^#{1,6}\s+', multiLine: true), '');
    text = text.replaceAllMapped(
      RegExp(r'\*\*([^*]+)\*\*'),
      (m) => m.group(1)!,
    );
    text = text.replaceAllMapped(
      RegExp('__([^_]+)__'),
      (m) => m.group(1)!,
    );
    text = text.replaceAllMapped(
      RegExp(r'\*([^*]+)\*'),
      (m) => m.group(1)!,
    );
    text = text.replaceAllMapped(
      RegExp('_([^_]+)_'),
      (m) => m.group(1)!,
    );
    text = text.replaceAllMapped(
      RegExp('~~([^~]+)~~'),
      (m) => m.group(1)!,
    );

    // Blockquotes and list markers.
    text = text.replaceAll(RegExp(r'^>\s?', multiLine: true), '');
    text = text.replaceAll(RegExp(r'^[\s]*[-*+]\s+', multiLine: true), '');
    text = text.replaceAll(RegExp(r'^[\s]*\d+\.\s+', multiLine: true), '');

    // Collapse whitespace.
    return text.replaceAll(RegExp(r'\n{3,}'), '\n\n').trim();
  }
}
