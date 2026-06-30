import 'dart:math' as math;

/// Small, pure formatting helpers used across the UI.
///
/// Kept free of Flutter imports so they can be unit tested without a binding.
abstract final class Formatters {
  static const List<String> _byteUnits = <String>[
    'B',
    'KB',
    'MB',
    'GB',
    'TB',
  ];

  /// Formats a byte count into a human-readable string, e.g. `1.2 GB`.
  static String bytes(int bytes, {int decimals = 1}) {
    if (bytes <= 0) return '0 B';
    final i = (math.log(bytes) / math.log(1024)).floor().clamp(
      0,
      _byteUnits.length - 1,
    );
    final value = bytes / math.pow(1024, i);
    return '${value.toStringAsFixed(i == 0 ? 0 : decimals)} ${_byteUnits[i]}';
  }

  /// Formats a tokens-per-second rate, e.g. `12.4 tok/s`.
  static String tokensPerSecond(double rate) {
    if (rate <= 0 || rate.isNaN || rate.isInfinite) return '— tok/s';
    return '${rate.toStringAsFixed(1)} tok/s';
  }

  /// Formats a [Duration] compactly as `m:ss` or `h:mm:ss`.
  static String duration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    String two(int n) => n.toString().padLeft(2, '0');
    return h > 0 ? '$h:${two(m)}:${two(s)}' : '$m:${two(s)}';
  }

  /// A short relative timestamp such as `now`, `5m`, `3h`, `2d`.
  static String relativeTime(DateTime time, {DateTime? now}) {
    final delta = (now ?? DateTime.now()).difference(time);
    if (delta.inSeconds < 45) return 'now';
    if (delta.inMinutes < 60) return '${delta.inMinutes}m';
    if (delta.inHours < 24) return '${delta.inHours}h';
    if (delta.inDays < 7) return '${delta.inDays}d';
    return '${delta.inDays ~/ 7}w';
  }
}
