import 'package:flutter_test/flutter_test.dart';
import 'package:manthan/features/tools/data/calculator_tool.dart';
import 'package:manthan/features/tools/data/date_time_tool.dart';
import 'package:manthan/features/tools/data/tool_call_parser.dart';
import 'package:manthan/features/tools/data/tool_prompt_builder.dart';
import 'package:manthan/features/tools/data/tool_registry.dart';
import 'package:manthan/features/tools/domain/on_device_tool.dart';

void main() {
  group('CalculatorTool', () {
    final tool = CalculatorTool();

    test('evaluates nested arithmetic', () async {
      final result = await tool.execute(<String, Object?>{
        'expression': '(12 + 3) * 4 / 2',
      });
      expect(result.isError, isFalse);
      expect(result.output, '30');
    });

    test('supports unary minus and decimals', () async {
      final result = await tool.execute(<String, Object?>{
        'expression': '-2.5 + 1',
      });
      expect(result.output, '-1.5');
    });

    test('rejects invalid input', () async {
      final result = await tool.execute(<String, Object?>{
        'expression': '2 + abc',
      });
      expect(result.isError, isTrue);
    });

    test('rejects division by zero', () async {
      final result = await tool.execute(<String, Object?>{
        'expression': '1/0',
      });
      expect(result.isError, isTrue);
      expect(result.output, contains('zero'));
    });
  });

  group('DateTimeTool', () {
    test('returns a fixed clock value', () async {
      final tool = DateTimeTool(clock: () => DateTime(2026, 8, 7, 20, 5, 0));
      final result = await tool.execute(const <String, Object?>{
        'part': 'both',
      });
      expect(result.isError, isFalse);
      expect(result.output, contains('2026-08-07T20:05:00'));
    });
  });

  group('ToolCallParser', () {
    test('parses a fenced tool call', () {
      const text = '''
<tool_call>
{"name":"calculator","arguments":{"expression":"2+2"}}
</tool_call>
''';
      final calls = ToolCallParser.parse(text);
      expect(calls, hasLength(1));
      expect(calls.single.name, 'calculator');
      expect(calls.single.arguments['expression'], '2+2');
    });

    test('strips tool call blocks', () {
      const text =
          'Before\n<tool_call>{"name":"x","arguments":{}}</tool_call>\nAfter';
      expect(ToolCallParser.stripToolCalls(text), 'Before\n\nAfter');
    });
  });

  group('ToolRegistry', () {
    test('executes registered tools and errors on unknown', () async {
      final registry = ToolRegistry.builtins(
        clock: () => DateTime(2026, 1, 1),
      );
      final ok = await registry.execute(
        const ToolCall(name: 'calculator', arguments: {'expression': '1+1'}),
      );
      expect(ok.output, '2');

      final missing = await registry.execute(
        const ToolCall(name: 'nope'),
      );
      expect(missing.isError, isTrue);
    });
  });

  group('ToolPromptBuilder', () {
    test('builds a non-empty appendix and merges prompts', () {
      final registry = ToolRegistry.builtins();
      final appendix = ToolPromptBuilder.build(registry.tools);
      expect(appendix, contains('calculator'));
      expect(appendix, contains('<tool_call>'));

      final merged = ToolPromptBuilder.mergeSystemPrompt(
        systemPrompt: 'Be concise.',
        toolsAppendix: appendix,
      );
      expect(merged, startsWith('Be concise.'));
      expect(merged, contains('calculator'));
    });
  });
}
