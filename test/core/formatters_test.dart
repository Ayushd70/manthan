import 'package:flutter_test/flutter_test.dart';
import 'package:manthan/core/utils/formatters.dart';

void main() {
  group('Formatters.bytes', () {
    test('formats zero and small values', () {
      expect(Formatters.bytes(0), '0 B');
      expect(Formatters.bytes(512), '512 B');
    });

    test('formats KB / MB / GB', () {
      expect(Formatters.bytes(1024), '1.0 KB');
      expect(Formatters.bytes(1024 * 1024), '1.0 MB');
      expect(Formatters.bytes(5 * 1024 * 1024 * 1024), '5.0 GB');
    });
  });

  group('Formatters.tokensPerSecond', () {
    test('handles invalid rates', () {
      expect(Formatters.tokensPerSecond(0), '— tok/s');
      expect(Formatters.tokensPerSecond(double.nan), '— tok/s');
    });

    test('formats a valid rate', () {
      expect(Formatters.tokensPerSecond(12.34), '12.3 tok/s');
    });
  });

  group('Formatters.relativeTime', () {
    test('returns compact deltas', () {
      final now = DateTime(2026, 6, 19, 12);
      expect(
        Formatters.relativeTime(
          now.subtract(const Duration(seconds: 5)),
          now: now,
        ),
        'now',
      );
      expect(
        Formatters.relativeTime(
          now.subtract(const Duration(minutes: 5)),
          now: now,
        ),
        '5m',
      );
      expect(
        Formatters.relativeTime(
          now.subtract(const Duration(hours: 3)),
          now: now,
        ),
        '3h',
      );
    });
  });
}
