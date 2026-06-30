import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Emits the process resident set size (RAM) periodically, for the in-app HUD.
///
/// Uses `ProcessInfo.currentRss` which is available on all native platforms
/// Manthan targets. Values are in bytes.
final StreamProvider<int> ramUsageProvider = StreamProvider<int>((ref) async* {
  int current() {
    try {
      return ProcessInfo.currentRss;
    } on Object {
      return 0;
    }
  }

  yield current();
  yield* Stream<int>.periodic(
    const Duration(seconds: 2),
    (_) => current(),
  );
});
