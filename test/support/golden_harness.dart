import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manthan/core/theme/app_theme.dart';

/// Shared harness for deterministic golden / pixel tests.
///
/// Avoids GoogleFonts network fetches by using a plain Material 3 theme with
/// the Manthan seed color, and pins a fixed surface size.
Widget goldenHarness({required Widget child}) {
  return ProviderScope(
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: AppTheme.seed),
      ),
      home: Scaffold(
        body: ColoredBox(
          color: ColorScheme.fromSeed(seedColor: AppTheme.seed).surface,
          child: Center(child: child),
        ),
      ),
    ),
  );
}

/// Pins a stable viewport for golden captures.
Future<void> setGoldenSurface(
  WidgetTester tester, {
  Size size = const Size(420, 640),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}
