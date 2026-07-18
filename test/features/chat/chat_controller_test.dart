import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manthan/core/providers.dart';
import 'package:manthan/features/chat/application/chat_controller.dart';
import 'package:manthan/features/chat/data/chat_repository.dart';
import 'package:manthan/features/chat/domain/chat_message.dart';
import 'package:manthan/features/chat/domain/chat_session.dart';
import 'package:manthan/features/inference/application/engine_controller.dart';
import 'package:manthan/features/inference/domain/generation_config.dart';
import 'package:manthan/features/settings/application/settings_controller.dart';
import 'package:manthan/features/settings/domain/app_settings.dart';

class _FakeChatRepository implements ChatRepository {
  final Map<String, ChatSession> _sessions = <String, ChatSession>{};

  @override
  List<ChatSession> loadSessions() => _sessions.values.toList();

  @override
  ChatSession? loadSession(String uid) => _sessions[uid];

  @override
  List<ChatMessage> loadMessages(String sessionUid) =>
      _sessions[sessionUid]?.messages ?? const <ChatMessage>[];

  @override
  void saveSession(ChatSession session) => _sessions[session.id] = session;

  @override
  void saveMessage(String sessionUid, ChatMessage message) {}

  @override
  void deleteSession(String uid) => _sessions.remove(uid);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeSettingsController extends SettingsController {
  @override
  AppSettings build() => const AppSettings();
}

void main() {
  group('ChatController', () {
    late ProviderContainer container;
    late _FakeChatRepository repo;

    setUp(() {
      repo = _FakeChatRepository();
      container = ProviderContainer(
        overrides: [
          chatRepositoryProvider.overrideWithValue(repo),
          settingsProvider.overrideWith(_FakeSettingsController.new),
        ],
      );
      addTearDown(container.dispose);
    });

    ChatController controller() =>
        container.read(chatControllerProvider.notifier);

    ChatState state() => container.read(chatControllerProvider);

    test('pinModel sets and persists the active session model', () {
      controller().newSession();
      controller().pinModel('gemma-2b');

      expect(state().active?.modelId, 'gemma-2b');
      expect(repo.loadSession(state().active!.id)?.modelId, 'gemma-2b');
    });

    test('pinModel(null) clears a pin', () {
      controller()
        ..newSession()
        ..pinModel('gemma-2b')
        ..pinModel(null);

      expect(state().active?.modelId, isNull);
    });

    test('setGenerationOverrides stores a per-session preset', () {
      const overrides = GenerationConfig(temperature: 0.3, maxTokens: 256);
      controller()
        ..newSession()
        ..setGenerationOverrides(overrides);

      expect(state().active?.generationOverrides, overrides);
      expect(
        repo.loadSession(state().active!.id)?.generationOverrides,
        overrides,
      );
    });

    test('pinModel is a no-op without an active session', () {
      controller().pinModel('gemma-2b');

      expect(state().active, isNull);
    });

    test('selectSession requests the pinned model on the engine', () async {
      final now = DateTime(2026);
      final pinned = ChatSession(
        id: 'pinned',
        title: 'Pinned chat',
        createdAt: now,
        updatedAt: now,
        modelId: 'unknown-model',
      );
      repo.saveSession(pinned);

      // Let the engine controller's own startup activation (triggered by
      // first read, unrelated to this session) settle before pinning.
      container.read(engineControllerProvider);
      await pumpEventQueue();

      controller().selectSession('pinned');
      await pumpEventQueue();

      final runtime = container.read(engineControllerProvider);
      expect(runtime.requestedModelId, 'unknown-model');
      // `unknown-model` isn't in the catalog, so we fall back to mock rather
      // than crashing — but the *request* is still tracked for comparison
      // on the next message/session switch.
      expect(runtime.activeModelId, isNull);
    });
  });
}
