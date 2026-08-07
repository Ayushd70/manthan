import 'package:manthan/features/tools/domain/on_device_tool.dart';

/// Evaluates simple arithmetic expressions on-device.
///
/// Supports `+`, `-`, `*`, `/`, `%`, parentheses, decimals, and unary minus.
/// Rejects anything else so the model cannot inject arbitrary code.
class CalculatorTool implements OnDeviceTool {
  @override
  String get name => 'calculator';

  @override
  String get description =>
      'Evaluate a basic arithmetic expression. Use for math questions.';

  @override
  Map<String, Object?> get parameters => const <String, Object?>{
    'type': 'object',
    'properties': <String, Object?>{
      'expression': <String, Object?>{
        'type': 'string',
        'description': 'Arithmetic expression, e.g. "(12 + 3) * 4 / 2"',
      },
    },
    'required': <String>['expression'],
  };

  @override
  Future<ToolResult> execute(Map<String, Object?> arguments) async {
    final raw = arguments['expression']?.toString().trim() ?? '';
    if (raw.isEmpty) {
      return const ToolResult(
        name: 'calculator',
        output: 'Missing expression argument.',
        isError: true,
      );
    }

    try {
      final value = _evaluate(raw);
      final formatted = value == value.roundToDouble()
          ? value.round().toString()
          : value.toString();
      return ToolResult(name: name, output: formatted);
    } on FormatException catch (e) {
      return ToolResult(
        name: name,
        output: e.message,
        isError: true,
      );
    }
  }

  /// Recursive-descent evaluator for a restricted arithmetic grammar.
  static double _evaluate(String input) {
    final parser = _ExprParser(input);
    final value = parser.parseExpression();
    parser.expectEnd();
    return value;
  }
}

class _ExprParser {
  _ExprParser(String input) : _src = input.replaceAll(' ', '');

  final String _src;
  int _i = 0;

  double parseExpression() {
    var value = parseTerm();
    while (_match('+') || _match('-')) {
      final op = _src[_i - 1];
      final right = parseTerm();
      value = op == '+' ? value + right : value - right;
    }
    return value;
  }

  double parseTerm() {
    var value = parseUnary();
    while (_match('*') || _match('/') || _match('%')) {
      final op = _src[_i - 1];
      final right = parseUnary();
      switch (op) {
        case '*':
          value *= right;
        case '/':
          if (right == 0) {
            throw const FormatException('Division by zero.');
          }
          value /= right;
        case '%':
          if (right == 0) {
            throw const FormatException('Modulo by zero.');
          }
          value %= right;
      }
    }
    return value;
  }

  double parseUnary() {
    if (_match('+')) return parseUnary();
    if (_match('-')) return -parseUnary();
    return parsePrimary();
  }

  double parsePrimary() {
    if (_match('(')) {
      final value = parseExpression();
      if (!_match(')')) {
        throw const FormatException('Missing closing parenthesis.');
      }
      return value;
    }
    return parseNumber();
  }

  double parseNumber() {
    final start = _i;
    while (_i < _src.length && _isDigit(_src[_i])) {
      _i++;
    }
    if (_i < _src.length && _src[_i] == '.') {
      _i++;
      while (_i < _src.length && _isDigit(_src[_i])) {
        _i++;
      }
    }
    if (start == _i) {
      throw FormatException(
        'Expected a number at position $start in "$_src".',
      );
    }
    return double.parse(_src.substring(start, _i));
  }

  bool _match(String ch) {
    if (_i < _src.length && _src[_i] == ch) {
      _i++;
      return true;
    }
    return false;
  }

  void expectEnd() {
    if (_i != _src.length) {
      throw FormatException('Unexpected character "${_src[_i]}" in "$_src".');
    }
  }

  static bool _isDigit(String ch) =>
      ch.compareTo('0') >= 0 && ch.compareTo('9') <= 0;
}
