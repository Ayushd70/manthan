import 'dart:convert';

import 'package:manthan/features/tools/domain/on_device_tool.dart';

/// Parses model-emitted tool invocations from free-form assistant text.
///
/// Recognizes fenced blocks:
/// ```xml
/// <tool_call>
/// {"name":"calculator","arguments":{"expression":"2+2"}}
/// </tool_call>
/// ```
/// and bare JSON objects with a `name` field.
abstract final class ToolCallParser {
  static final RegExp _blockPattern = RegExp(
    r'<tool_call>\s*([\s\S]*?)\s*</tool_call>',
    caseSensitive: false,
  );

  /// Extracts zero or more [ToolCall]s from [text].
  static List<ToolCall> parse(String text) {
    final calls = <ToolCall>[];

    for (final match in _blockPattern.allMatches(text)) {
      final call = _parseJson(match.group(1)!);
      if (call != null) calls.add(call);
    }

    if (calls.isEmpty) {
      final trimmed = text.trim();
      if (trimmed.startsWith('{') && trimmed.contains('"name"')) {
        final call = _parseJson(trimmed);
        if (call != null) calls.add(call);
      }
    }

    return calls;
  }

  /// True when [text] contains at least one tool-call marker or JSON call.
  static bool hasToolCall(String text) => parse(text).isNotEmpty;

  /// Removes `<tool_call>…</tool_call>` blocks from [text] for display.
  static String stripToolCalls(String text) {
    final stripped = text.replaceAll(_blockPattern, '').trim();
    return stripped;
  }

  static ToolCall? _parseJson(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      final name = decoded['name']?.toString();
      if (name == null || name.isEmpty) return null;

      final argsRaw =
          decoded['arguments'] ?? decoded['parameters'] ?? decoded['args'];
      final args = <String, Object?>{};
      if (argsRaw is Map) {
        argsRaw.forEach((key, value) {
          args['$key'] = value;
        });
      }

      return ToolCall(name: name, arguments: args);
    } on FormatException {
      return null;
    } on Object {
      return null;
    }
  }
}
