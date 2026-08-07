import 'package:intl/intl.dart';
import 'package:manthan/features/tools/domain/on_device_tool.dart';

/// Returns the device's current date and/or time.
class DateTimeTool implements OnDeviceTool {
  DateTimeTool({DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  final DateTime Function() _clock;

  @override
  String get name => 'date_time';

  @override
  String get description =>
      'Get the current local date and time on this device. '
      'Use when the user asks what day, date, or time it is.';

  @override
  Map<String, Object?> get parameters => const <String, Object?>{
    'type': 'object',
    'properties': <String, Object?>{
      'part': <String, Object?>{
        'type': 'string',
        'description': 'One of "date", "time", or "both" (default).',
        'enum': <String>['date', 'time', 'both'],
      },
    },
  };

  @override
  Future<ToolResult> execute(Map<String, Object?> arguments) async {
    final now = _clock();
    final part = (arguments['part']?.toString().toLowerCase() ?? 'both').trim();

    final date = DateFormat.yMMMMEEEEd().format(now);
    final time = DateFormat.jms().format(now);
    final iso = now.toIso8601String();

    final String output;
    switch (part) {
      case 'date':
        output = '$date ($iso)';
      case 'time':
        output = '$time ($iso)';
      case 'both':
      default:
        output = '$date, $time ($iso)';
    }

    return ToolResult(name: name, output: output);
  }
}
