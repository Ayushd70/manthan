import 'package:equatable/equatable.dart';

/// A single argument-bearing invocation requested by the model.
class ToolCall extends Equatable {
  const ToolCall({
    required this.name,
    this.arguments = const <String, Object?>{},
  });

  /// Registered tool name, e.g. `calculator`.
  final String name;

  /// JSON-compatible argument map supplied by the model.
  final Map<String, Object?> arguments;

  @override
  List<Object?> get props => <Object?>[name, arguments];
}

/// Outcome of executing a [ToolCall].
class ToolResult extends Equatable {
  const ToolResult({
    required this.name,
    required this.output,
    this.isError = false,
  });

  /// Tool that produced this result.
  final String name;

  /// Human-readable (and model-readable) result text.
  final String output;

  /// True when execution failed.
  final bool isError;

  @override
  List<Object?> get props => <Object?>[name, output, isError];
}

/// Contract for an on-device utility the model can invoke.
abstract interface class OnDeviceTool {
  /// Stable identifier used in tool-call JSON (`name` field).
  String get name;

  /// Short description shown to the model in the tools system prompt.
  String get description;

  /// JSON-Schema-ish parameter object (`type`/`properties`/`required`).
  Map<String, Object?> get parameters;

  /// Runs the tool with [arguments] from a [ToolCall].
  Future<ToolResult> execute(Map<String, Object?> arguments);
}
