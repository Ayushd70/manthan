import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:manthan/app/router.dart';
import 'package:manthan/core/constants/app_info.dart';
import 'package:manthan/core/providers.dart';
import 'package:manthan/data/local/secure_key_store.dart';
import 'package:manthan/features/models/domain/model_catalog.dart';
import 'package:manthan/features/onboarding/presentation/onboarding_page.dart';
import 'package:manthan/features/settings/application/settings_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('onboarding shows brand and completes to chat', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();

    final router = GoRouter(
      initialLocation: Routes.onboarding,
      routes: <RouteBase>[
        GoRoute(
          path: Routes.onboarding,
          builder: (context, state) => const OnboardingPage(),
        ),
        GoRoute(
          path: Routes.chat,
          builder: (context, state) => const Scaffold(body: Text('chat-home')),
        ),
        GoRoute(
          path: Routes.models,
          builder: (context, state) =>
              const Scaffold(body: Text('models-home')),
        ),
      ],
    );

    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        secureKeyStoreProvider.overrideWithValue(MemorySecureKeyStore()),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(OnboardingPage), findsOneWidget);
    expect(find.text(AppInfo.name), findsOneWidget);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text(ModelCatalog.starter.name), findsWidgets);

    await tester.tap(find.text('Start chatting'));
    await tester.pumpAndSettle();

    expect(find.text('chat-home'), findsOneWidget);
    expect(container.read(settingsProvider).hasCompletedOnboarding, isTrue);
  });
}
