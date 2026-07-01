import 'dart:async';
import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manthan/core/demo/demo_seed.dart';
import 'package:manthan/core/providers.dart';
import 'package:manthan/features/chat/domain/chat_message.dart';
import 'package:manthan/features/chat/domain/chat_session.dart';
import 'package:manthan/features/inference/application/engine_controller.dart';
import 'package:manthan/features/inference/domain/llm_engine.dart';
import 'package:manthan/features/rag/application/rag_controller.dart';
import 'package:manthan/features/settings/application/settings_controller.dart';
import 'package:manthan/features/voice/application/tts_controller.dart';
import 'package:uuid/uuid.dart';

/// Observable state of the chat feature.
class ChatState extends Equatable {
  const ChatState({
    this.sessions = const <ChatSession>[],
    this.active,
    this.isGenerating = false,
  });

  /// All known sessions (metadata only), newest first.
  final List<ChatSession> sessions;

  /// The currently open session including its messages.
  final ChatSession? active;

  /// True while an assistant response is streaming.
  final bool isGenerating;

  ChatState copyWith({
    List<ChatSession>? sessions,
    ChatSession? Function()? active,
    bool? isGenerating,
  }) {
    return ChatState(
      sessions: sessions ?? this.sessions,
      active: active != null ? active() : this.active,
      isGenerating: isGenerating ?? this.isGenerating,
    );
  }

  @override
  List<Object?> get props => <Object?>[sessions, active, isGenerating];
}

/// Drives conversations: persistence, streaming generation, and tokens/sec.
class ChatController extends Notifier<ChatState> {
  static const _uuid = Uuid();

  StreamSubscription<GenerationChunk>? _sub;

  @override
  ChatState build() {
    ref.onDispose(() => _sub?.cancel());
    if (DemoSeed.enabled) {
      final demo = DemoSeed.session();
      return ChatState(sessions: <ChatSession>[demo], active: demo);
    }
    final repo = ref.read(chatRepositoryProvider);
    final sessions = repo.loadSessions();
    final active = sessions.isNotEmpty
        ? repo.loadSession(sessions.first.id)
        : null;
    return ChatState(sessions: sessions, active: active);
  }

  /// Starts a new, empty conversation and makes it active.
  void newSession({bool documentScoped = false}) {
    final now = DateTime.now();
    final session = ChatSession(
      id: _uuid.v4(),
      title: 'New chat',
      createdAt: now,
      updatedAt: now,
      documentScoped: documentScoped,
    );
    state = state.copyWith(active: () => session);
  }

  /// Opens an existing session by id.
  void selectSession(String id) {
    final repo = ref.read(chatRepositoryProvider);
    final session = repo.loadSession(id);
    if (session != null) state = state.copyWith(active: () => session);
  }

  /// Deletes a session and selects the next available one.
  void deleteSession(String id) {
    final repo = ref.read(chatRepositoryProvider)..deleteSession(id);
    final sessions = repo.loadSessions();
    final active = state.active?.id == id
        ? (sessions.isNotEmpty ? repo.loadSession(sessions.first.id) : null)
        : state.active;
    state = ChatState(
      sessions: sessions,
      active: active,
    );
  }

  /// Toggles whether the active session is grounded against documents (RAG).
  void setDocumentScoped({required bool enabled}) {
    final active = state.active;
    if (active == null) {
      newSession(documentScoped: enabled);
      return;
    }
    state = state.copyWith(
      active: () => active.copyWith(documentScoped: enabled),
    );
  }

  /// Sends a user [text] (with optional [images]) and streams the reply.
  Future<void> sendMessage(
    String text, {
    List<Uint8List> images = const <Uint8List>[],
  }) async {
    final trimmed = text.trim();
    if ((trimmed.isEmpty && images.isEmpty) || state.isGenerating) return;

    await ref.read(ttsControllerProvider.notifier).stop();

    final repo = ref.read(chatRepositoryProvider);
    var session =
        state.active ??
        ChatSession(
          id: _uuid.v4(),
          title: 'New chat',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

    final userMessage = ChatMessage(
      id: _uuid.v4(),
      role: ChatRole.user,
      text: trimmed,
      images: images,
      createdAt: DateTime.now(),
    );

    final isFirstMessage = session.messages.isEmpty;
    session = session.copyWith(
      title: isFirstMessage ? _deriveTitle(trimmed) : session.title,
      updatedAt: DateTime.now(),
      messages: <ChatMessage>[...session.messages, userMessage],
    );

    repo
      ..saveSession(session)
      ..saveMessage(session.id, userMessage);

    // Optionally ground the prompt with retrieved document context.
    var contextSources = const <String>[];
    var history = session.messages;
    if (session.documentScoped) {
      final retrieval = await ref
          .read(ragControllerProvider.notifier)
          .retrieve(trimmed);
      if (retrieval.context.isNotEmpty) {
        contextSources = retrieval.sources;
        history = _injectContext(session.messages, retrieval.context);
      }
    }

    final assistantMessage = ChatMessage(
      id: _uuid.v4(),
      role: ChatRole.assistant,
      text: '',
      createdAt: DateTime.now(),
      isStreaming: true,
      sources: contextSources,
    );

    session = session.copyWith(
      messages: <ChatMessage>[...session.messages, assistantMessage],
    );
    state = state.copyWith(active: () => session, isGenerating: true);

    await _streamResponse(
      sessionId: session.id,
      assistantId: assistantMessage.id,
      history: history,
      images: images,
      sources: contextSources,
    );
  }

  /// Stops the in-flight generation, keeping whatever was produced so far.
  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
    final engine = ref.read(engineControllerProvider).engine;
    await engine?.stop();
    _finalizeStreaming();
  }

  Future<void> _streamResponse({
    required String sessionId,
    required String assistantId,
    required List<ChatMessage> history,
    required List<Uint8List> images,
    required List<String> sources,
  }) async {
    final engineController = ref.read(engineControllerProvider.notifier);
    var runtime = ref.read(engineControllerProvider);
    if (!runtime.isReady) {
      await engineController.activate(
        ref.read(engineControllerProvider).activeModelId,
      );
      runtime = ref.read(engineControllerProvider);
    }
    final engine = runtime.engine;
    if (engine == null) {
      _completeWithError(sessionId, assistantId, 'No engine available.');
      return;
    }

    final buffer = StringBuffer();
    final stopwatch = Stopwatch()..start();
    var tokenCount = 0;

    await _sub?.cancel();
    final completer = Completer<void>();
    _sub = engine
        .generate(history, images: images)
        .listen(
          (chunk) {
            if (chunk.isThinking) return;
            buffer.write(chunk.textDelta);
            tokenCount++;
            _updateAssistant(
              sessionId,
              assistantId,
              text: buffer.toString(),
              isStreaming: true,
              sources: sources,
            );
          },
          onError: (Object error) {
            _completeWithError(sessionId, assistantId, error.toString());
            if (!completer.isCompleted) completer.complete();
          },
          onDone: () {
            stopwatch.stop();
            final seconds = stopwatch.elapsedMilliseconds / 1000.0;
            final rate = seconds > 0 ? tokenCount / seconds : 0.0;
            _updateAssistant(
              sessionId,
              assistantId,
              text: buffer.isEmpty ? '(no output)' : buffer.toString(),
              isStreaming: false,
              tokensPerSecond: rate,
              tokenCount: tokenCount,
              sources: sources,
              persist: true,
            );
            state = state.copyWith(isGenerating: false);
            _sub = null;
            _maybeAutoSpeak(assistantId, buffer.toString());
            if (!completer.isCompleted) completer.complete();
          },
          cancelOnError: true,
        );

    await completer.future;
  }

  void _updateAssistant(
    String sessionId,
    String assistantId, {
    required String text,
    required bool isStreaming,
    double? tokensPerSecond,
    int? tokenCount,
    List<String> sources = const <String>[],
    bool persist = false,
  }) {
    final active = state.active;
    if (active == null || active.id != sessionId) return;

    final messages = active.messages.map((m) {
      if (m.id != assistantId) return m;
      return m.copyWith(
        text: text,
        isStreaming: isStreaming,
        tokensPerSecond: tokensPerSecond,
        tokenCount: tokenCount,
        sources: sources,
      );
    }).toList();

    final updated = active.copyWith(
      messages: messages,
      updatedAt: DateTime.now(),
    );
    state = state.copyWith(active: () => updated);

    if (persist) {
      final repo = ref.read(chatRepositoryProvider);
      final assistant = messages.firstWhere((m) => m.id == assistantId);
      repo
        ..saveSession(updated)
        ..saveMessage(sessionId, assistant);
      state = state.copyWith(sessions: repo.loadSessions());
    }
  }

  void _completeWithError(
    String sessionId,
    String assistantId,
    String error,
  ) {
    final active = state.active;
    if (active == null) return;
    final messages = active.messages.map((m) {
      if (m.id != assistantId) return m;
      return m.copyWith(
        text: 'Generation failed: $error',
        isStreaming: false,
        isError: true,
      );
    }).toList();
    final updated = active.copyWith(messages: messages);
    state = state.copyWith(active: () => updated, isGenerating: false);
    ref
        .read(chatRepositoryProvider)
        .saveMessage(
          sessionId,
          messages.firstWhere((m) => m.id == assistantId),
        );
    _sub = null;
  }

  void _finalizeStreaming() {
    final active = state.active;
    if (active == null) return;
    final messages = active.messages
        .map((m) => m.isStreaming ? m.copyWith(isStreaming: false) : m)
        .toList();
    final updated = active.copyWith(messages: messages);
    state = state.copyWith(active: () => updated, isGenerating: false);
    final repo = ref.read(chatRepositoryProvider);
    for (final m in messages.where((m) => m.role == ChatRole.assistant)) {
      repo.saveMessage(active.id, m);
    }
  }

  List<ChatMessage> _injectContext(
    List<ChatMessage> messages,
    String context,
  ) {
    if (messages.isEmpty) return messages;
    final last = messages.last;
    final grounded = last.copyWith(
      text:
          'Use the following context to answer the question. If the answer '
          'is not contained in the context, say so.\n\n'
          '--- CONTEXT ---\n$context\n--- END CONTEXT ---\n\n'
          'Question: ${last.text}',
    );
    return <ChatMessage>[...messages.sublist(0, messages.length - 1), grounded];
  }

  String _deriveTitle(String text) {
    final firstLine = text.split('\n').first.trim();
    if (firstLine.length <= 40) return firstLine;
    return '${firstLine.substring(0, 40)}…';
  }

  void _maybeAutoSpeak(String messageId, String text) {
    if (!ref.read(settingsProvider).autoSpeakReplies) return;
    if (text.trim().isEmpty || text == '(no output)') return;
    unawaited(
      ref
          .read(ttsControllerProvider.notifier)
          .speakMessage(
            messageId: messageId,
            markdownText: text,
          ),
    );
  }
}

/// Global chat provider.
final chatControllerProvider = NotifierProvider<ChatController, ChatState>(
  ChatController.new,
);
