import 'dart:convert';

import 'package:manthan/features/tools/domain/on_device_tool.dart';

/// Builds the system-prompt appendix that teaches the model the tool protocol.
abstract final class ToolPromptBuilder {
  /// Instructions + catalog for [tools]. Empty string when [tools] is empty.
  static String build(List<OnDeviceTool> tools) {
    if (tools.isEmpty) return '';

    final catalog = StringBuffer();
    for (final tool in tools) {
      catalog.writeln('- ${tool.name}: ${tool.description}');
      catalog.writeln('  parameters: ${jsonEncode(tool.parameters)}');
    }

    return '''
You have access to on-device tools. When a tool would help, respond with ONLY a tool call in this exact format (no other text):

<tool_call>
{"name":"tool_name","arguments":{...}}
</tool_call>

After you receive a tool result, answer the user in natural language using that result. Do not invent tool results.

Available tools:
$catalog'''
        .trim();
  }

  /// Merges [toolsAppendix] into an existing [systemPrompt], if any.
  static String? mergeSystemPrompt({
    required String? systemPrompt,
    required String toolsAppendix,
  }) {
    if (toolsAppendix.isEmpty) return systemPrompt;
    if (systemPrompt == null || systemPrompt.trim().isEmpty) {
      return toolsAppendix;
    }
    return '${systemPrompt.trim()}\n\n$toolsAppendix';
  }

  /// Formats [results] so they can be appended to the generation history.
  static String formatResults(List<ToolResult> results) {
    final buffer = StringBuffer();
    for (final result in results) {
      final tag = result.isError ? 'error' : 'result';
      buffer.writeln('Tool $tag (${result.name}): ${result.output}');
    }
    return buffer.toString().trim();
  }
}
