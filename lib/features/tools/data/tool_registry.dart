import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manthan/features/tools/data/calculator_tool.dart';
import 'package:manthan/features/tools/data/date_time_tool.dart';
import 'package:manthan/features/tools/domain/on_device_tool.dart';

/// Lookup table for on-device tools the chat loop can invoke.
class ToolRegistry {
  ToolRegistry(List<OnDeviceTool> tools)
    : _byName = <String, OnDeviceTool>{
        for (final tool in tools) tool.name: tool,
      };

  /// Default calculator + date/time utilities.
  factory ToolRegistry.builtins({DateTime Function()? clock}) {
    return ToolRegistry(<OnDeviceTool>[
      CalculatorTool(),
      DateTimeTool(clock: clock),
    ]);
  }

  final Map<String, OnDeviceTool> _byName;

  /// All registered tools, in insertion order.
  List<OnDeviceTool> get tools =>
      List<OnDeviceTool>.unmodifiable(_byName.values);

  /// Resolves a tool by [name], or null if unknown.
  OnDeviceTool? operator [](String name) => _byName[name];

  /// Executes [call], returning an error [ToolResult] for unknown tools.
  Future<ToolResult> execute(ToolCall call) async {
    final tool = _byName[call.name];
    if (tool == null) {
      return ToolResult(
        name: call.name,
        output: 'Unknown tool "${call.name}".',
        isError: true,
      );
    }
    return tool.execute(call.arguments);
  }
}

/// App-wide tool registry (calculator, date/time, …).
final toolRegistryProvider = Provider<ToolRegistry>(
  (ref) => ToolRegistry.builtins(),
);
