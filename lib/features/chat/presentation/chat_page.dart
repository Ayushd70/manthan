import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manthan/app/router.dart';
import 'package:manthan/core/perf/perf_monitor.dart';
import 'package:manthan/core/utils/formatters.dart';
import 'package:manthan/features/chat/application/chat_controller.dart';
import 'package:manthan/features/chat/domain/chat_message.dart';
import 'package:manthan/features/chat/domain/chat_session.dart';
import 'package:manthan/features/chat/presentation/widgets/chat_input.dart';
import 'package:manthan/features/chat/presentation/widgets/message_bubble.dart';
import 'package:manthan/features/chat/presentation/widgets/sessions_drawer.dart';
import 'package:manthan/features/inference/application/engine_controller.dart';
import 'package:share_plus/share_plus.dart';

/// The primary conversation screen.
class ChatPage extends ConsumerStatefulWidget {
  const ChatPage({super.key});

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      unawaited(
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(chatControllerProvider);
    final controller = ref.read(chatControllerProvider.notifier);
    final engine = ref.watch(engineControllerProvider);
    final ram = ref.watch(ramUsageProvider).value;
    final active = state.active;

    ref.listen(chatControllerProvider, (_, _) => _scrollToEnd());

    return Scaffold(
      drawer: const SessionsDrawer(),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text('Manthan'),
            Text(
              _engineSubtitle(engine, ram),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: <Widget>[
          IconButton(
            tooltip: active?.documentScoped ?? false
                ? 'Document grounding on'
                : 'Document grounding off',
            icon: Icon(
              active?.documentScoped ?? false
                  ? Icons.auto_stories
                  : Icons.auto_stories_outlined,
            ),
            onPressed: () => controller.setDocumentScoped(
              enabled: !(active?.documentScoped ?? false),
            ),
          ),
          if (active != null && active.messages.isNotEmpty)
            IconButton(
              tooltip: 'Share conversation',
              icon: const Icon(Icons.ios_share),
              onPressed: () => _shareConversation(active),
            ),
          IconButton(
            tooltip: 'New chat',
            icon: const Icon(Icons.edit_square),
            onPressed: controller.newSession,
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          if (engine.usingFallback) _FallbackBanner(engine: engine),
          Expanded(
            child: (active == null || active.messages.isEmpty)
                ? _EmptyState(
                    documentScoped: active?.documentScoped ?? false,
                    onSuggestionTap: (text) =>
                        unawaited(controller.sendMessage(text)),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                    itemCount: active.messages.length,
                    itemBuilder: (context, i) =>
                        MessageBubble(message: active.messages[i]),
                  ),
          ),
          ChatInput(
            isGenerating: state.isGenerating,
            allowImages: engine.engine?.capabilities.supportsImages ?? false,
            onSend: (text, images) =>
                controller.sendMessage(text, images: images),
            onStop: controller.stop,
          ),
        ],
      ),
    );
  }

  Future<void> _shareConversation(ChatSession session) async {
    final buffer = StringBuffer('# ${session.title}\n\n')
      ..writeln('_Generated on-device with Manthan._\n');
    for (final m in session.messages) {
      if (m.role == ChatRole.system) continue;
      final who = m.role == ChatRole.user ? 'You' : 'Manthan';
      buffer.writeln('**$who:** ${m.text}\n');
    }
    await SharePlus.instance.share(
      ShareParams(text: buffer.toString(), subject: session.title),
    );
  }

  String _engineSubtitle(EngineRuntimeState engine, int? ramBytes) {
    final ram = (ramBytes != null && ramBytes > 0)
        ? ' · ${Formatters.bytes(ramBytes)} RAM'
        : '';
    return switch (engine.status) {
      EngineStatus.loading => 'Loading model…',
      EngineStatus.error => 'Engine error',
      EngineStatus.idle => 'Starting…',
      EngineStatus.ready => '${engine.displayName} · on-device$ram',
    };
  }
}

class _FallbackBanner extends StatelessWidget {
  const _FallbackBanner({required this.engine});
  final EngineRuntimeState engine;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.tertiaryContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: <Widget>[
            Icon(
              Icons.info_outline,
              size: 18,
              color: theme.colorScheme.onTertiaryContainer,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Using the built-in demo model. Download a real model from the '
                'Models tab for genuine answers.',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onTertiaryContainer,
                ),
              ),
            ),
            TextButton(
              onPressed: () => context.go(Routes.models),
              child: const Text('Models'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.onSuggestionTap,
    required this.documentScoped,
  });

  final void Function(String text) onSuggestionTap;
  final bool documentScoped;

  static const _suggestions = <String>[
    'Explain how on-device AI keeps my data private',
    'Write a haiku about offline computing',
    'Give me a Dart function to debounce calls',
    'What can you help me with?',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(Icons.blur_on, size: 64, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              documentScoped ? 'Chat with your documents' : 'Ask me anything',
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              documentScoped
                  ? 'Answers are grounded in the documents you imported — '
                        'fully offline.'
                  : 'Everything runs on your device. Nothing leaves it.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: <Widget>[
                for (final suggestion in _suggestions)
                  ActionChip(
                    label: Text(suggestion),
                    onPressed: () => onSuggestionTap(suggestion),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
