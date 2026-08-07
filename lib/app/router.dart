import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manthan/core/demo/demo_seed.dart';
import 'package:manthan/features/chat/presentation/chat_page.dart';
import 'package:manthan/features/home/presentation/home_shell.dart';
import 'package:manthan/features/models/presentation/models_page.dart';
import 'package:manthan/features/onboarding/presentation/onboarding_page.dart';
import 'package:manthan/features/prompts/presentation/prompt_library_page.dart';
import 'package:manthan/features/rag/presentation/documents_page.dart';
import 'package:manthan/features/settings/application/settings_controller.dart';
import 'package:manthan/features/settings/presentation/settings_page.dart';

/// Route path constants.
abstract final class Routes {
  static const chat = '/';
  static const models = '/models';
  static const documents = '/documents';
  static const settings = '/settings';
  static const prompts = '/settings/prompts';
  static const onboarding = '/onboarding';
}

/// Notifies [GoRouter] when settings that affect redirects change.
class _RouterRefresh extends ChangeNotifier {
  _RouterRefresh(Ref ref) {
    _subscription = ref.listen<bool>(
      settingsProvider.select((s) => s.hasCompletedOnboarding),
      (_, _) => notifyListeners(),
    );
  }

  late final ProviderSubscription<bool> _subscription;

  @override
  void dispose() {
    _subscription.close();
    super.dispose();
  }
}

/// Application router with a persistent bottom-navigation shell.
final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _RouterRefresh(ref);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: DemoSeed.initialLocation,
    refreshListenable: refresh,
    redirect: (context, state) {
      // Demo screenshot builds skip the welcome flow.
      if (DemoSeed.enabled) return null;

      final completed = ref.read(settingsProvider).hasCompletedOnboarding;
      final onOnboarding = state.matchedLocation == Routes.onboarding;

      if (!completed && !onOnboarding) return Routes.onboarding;
      if (completed && onOnboarding) return Routes.chat;
      return null;
    },
    routes: <RouteBase>[
      GoRoute(
        path: Routes.onboarding,
        builder: (context, state) => const OnboardingPage(),
      ),
      ShellRoute(
        builder: (context, state, child) => HomeShell(child: child),
        routes: <RouteBase>[
          GoRoute(
            path: Routes.chat,
            pageBuilder: (context, state) =>
                const NoTransitionPage<void>(child: ChatPage()),
          ),
          GoRoute(
            path: Routes.models,
            pageBuilder: (context, state) =>
                const NoTransitionPage<void>(child: ModelsPage()),
          ),
          GoRoute(
            path: Routes.documents,
            pageBuilder: (context, state) =>
                const NoTransitionPage<void>(child: DocumentsPage()),
          ),
          GoRoute(
            path: Routes.settings,
            pageBuilder: (context, state) =>
                const NoTransitionPage<void>(child: SettingsPage()),
          ),
          GoRoute(
            path: Routes.prompts,
            pageBuilder: (context, state) =>
                const NoTransitionPage<void>(child: PromptLibraryPage()),
          ),
        ],
      ),
    ],
  );
});
