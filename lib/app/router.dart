import 'package:go_router/go_router.dart';
import 'package:manthan/core/demo/demo_seed.dart';
import 'package:manthan/features/chat/presentation/chat_page.dart';
import 'package:manthan/features/home/presentation/home_shell.dart';
import 'package:manthan/features/models/presentation/models_page.dart';
import 'package:manthan/features/prompts/presentation/prompt_library_page.dart';
import 'package:manthan/features/rag/presentation/documents_page.dart';
import 'package:manthan/features/settings/presentation/settings_page.dart';

/// Route path constants.
abstract final class Routes {
  static const chat = '/';
  static const models = '/models';
  static const documents = '/documents';
  static const settings = '/settings';
  static const prompts = '/settings/prompts';
}

/// Application router with a persistent bottom-navigation shell.
final appRouter = GoRouter(
  initialLocation: DemoSeed.initialLocation,
  routes: <RouteBase>[
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
