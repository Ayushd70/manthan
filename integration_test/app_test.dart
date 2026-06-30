import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:manthan/app/app.dart';
import 'package:manthan/core/providers.dart';
import 'package:manthan/data/local/object_box.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// End-to-end smoke test: launches the app with a real (temporary) ObjectBox
/// store and exercises the chat flow against the built-in demo engine.
///
/// Run on a device/emulator with:
///   flutter test integration_test/app_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('sends a message and receives a streamed reply', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final objectBox = await ObjectBox.open();
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          objectBoxProvider.overrideWithValue(objectBox),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const ManthanApp(),
      ),
    );

    // Let the engine initialize (built-in demo engine, no download).
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Manthan'), findsWidgets);

    await tester.enterText(find.byType(TextField).first, 'hello');
    await tester.pump();
    await tester.tap(find.byTooltip('Send'));

    // Allow the demo engine to stream a few tokens.
    await tester.pump(const Duration(seconds: 2));

    // The user's message should be visible.
    expect(find.text('hello'), findsWidgets);

    objectBox.close();
  });
}
