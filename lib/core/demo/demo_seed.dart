import 'package:manthan/features/chat/domain/chat_message.dart';
import 'package:manthan/features/chat/domain/chat_session.dart';
import 'package:manthan/features/rag/domain/document.dart';

/// Lightweight, opt-in demo helpers used only for capturing marketing
/// screenshots / GIFs. Everything here is gated behind a compile-time
/// `--dart-define`, so it is completely inert (and dead code) in normal builds.
abstract final class DemoSeed {
  /// True when built with `--dart-define=MANTHAN_DEMO=true`, used to
  /// pre-populate a sample conversation and documents for screenshots.
  static const bool enabled = bool.fromEnvironment('MANTHAN_DEMO');

  static const String _screen = String.fromEnvironment('MANTHAN_SCREEN');

  /// Optional initial route for screenshots, e.g.
  /// `--dart-define=MANTHAN_SCREEN=models`.
  static String get initialLocation {
    switch (_screen) {
      case 'models':
        return '/models';
      case 'documents':
        return '/documents';
      case 'settings':
        return '/settings';
      case 'chat':
      default:
        return '/';
    }
  }

  /// A polished, deterministic conversation that exercises markdown, code
  /// blocks, throughput metrics, and RAG citations for the chat screenshot.
  static ChatSession session() {
    final now = DateTime.now();
    return ChatSession(
      id: 'demo-session',
      title: 'On-device privacy',
      createdAt: now,
      updatedAt: now,
      documentScoped: true,
      messages: <ChatMessage>[
        ChatMessage(
          id: 'm1',
          role: ChatRole.user,
          text: 'Explain how on-device AI keeps my data private',
          createdAt: now,
        ),
        ChatMessage(
          id: 'm2',
          role: ChatRole.assistant,
          createdAt: now,
          tokensPerSecond: 42.3,
          tokenCount: 128,
          text:
              'On-device AI keeps your data private by design:\n\n'
              '- **No network during inference** — prompts and responses never '
              'leave the device.\n'
              '- **Local storage only** — conversations live in an on-device '
              'database, not the cloud.\n'
              '- **No accounts or API keys** — nothing to leak and no third '
              'party in the loop.\n\n'
              'Switch on airplane mode and everything keeps working.',
        ),
        ChatMessage(
          id: 'm3',
          role: ChatRole.user,
          text: 'Now write a Dart function to debounce calls',
          createdAt: now,
        ),
        ChatMessage(
          id: 'm4',
          role: ChatRole.assistant,
          createdAt: now,
          tokensPerSecond: 38.7,
          tokenCount: 96,
          sources: const <String>['flutter_patterns.md', 'async_in_dart.md'],
          text:
              'Here is a reusable debouncer in Dart:\n\n'
              '```dart\n'
              "import 'dart:async';\n\n"
              'class Debouncer {\n'
              '  Debouncer(this.delay);\n'
              '  final Duration delay;\n'
              '  Timer? _timer;\n\n'
              '  void run(void Function() action) {\n'
              '    _timer?.cancel();\n'
              '    _timer = Timer(delay, action);\n'
              '  }\n\n'
              '  void dispose() => _timer?.cancel();\n'
              '}\n'
              '```\n\n'
              'Call `run()` on every event; only the last one within `delay` '
              'fires.',
        ),
      ],
    );
  }

  /// Sample imported documents for the RAG screenshot.
  static List<DocumentInfo> documents() {
    final now = DateTime.now();
    return <DocumentInfo>[
      DocumentInfo(
        id: 'doc-1',
        title: 'privacy_whitepaper.md',
        addedAt: now.subtract(const Duration(minutes: 8)),
        chunkCount: 12,
        charCount: 18432,
      ),
      DocumentInfo(
        id: 'doc-2',
        title: 'flutter_patterns.md',
        addedAt: now.subtract(const Duration(hours: 3)),
        chunkCount: 9,
        charCount: 13290,
      ),
      DocumentInfo(
        id: 'doc-3',
        title: 'async_in_dart.md',
        addedAt: now.subtract(const Duration(days: 1)),
        chunkCount: 7,
        charCount: 9874,
      ),
    ];
  }

  /// Total indexed chunk count for the seeded documents.
  static int get chunkCount =>
      documents().fold(0, (sum, d) => sum + d.chunkCount);
}
