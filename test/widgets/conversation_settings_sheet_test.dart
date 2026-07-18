import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manthan/core/providers.dart';
import 'package:manthan/features/chat/data/chat_repository.dart';
import 'package:manthan/features/chat/domain/chat_message.dart';
import 'package:manthan/features/chat/domain/chat_session.dart';
import 'package:manthan/features/chat/presentation/widgets/conversation_settings_sheet.dart';
import 'package:manthan/features/models/application/models_controller.dart';
import 'package:manthan/features/models/domain/model_catalog.dart';
import 'package:manthan/features/models/domain/model_download.dart';
import 'package:manthan/features/settings/application/settings_controller.dart';
import 'package:manthan/features/settings/domain/app_settings.dart';

class _FakeChatRepository implements ChatRepository {
  final Map<String, ChatSession> sessions = <String, ChatSession>{};

  @override
  List<ChatSession> loadSessions() => sessions.values.toList();

  @override
  ChatSession? loadSession(String uid) => sessions[uid];

  @override
  List<ChatMessage> loadMessages(String sessionUid) =>
      sessions[sessionUid]?.messages ?? const <ChatMessage>[];

  @override
  void saveSession(ChatSession session) => sessions[session.id] = session;

  @override
  void saveMessage(String sessionUid, ChatMessage message) {}

  @override
  void deleteSession(String uid) => sessions.remove(uid);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeSettingsController extends SettingsController {
  @override
  AppSettings build() => const AppSettings();
}

class _FakeModelsController extends ModelsController {
  @override
  Map<String, ModelDownload> build() => <String, ModelDownload>{
    ModelCatalog.all.first.id: const ModelDownload(
      modelId: 'downloaded',
      status: ModelDownloadStatus.downloaded,
    ),
  };
}

void main() {
  group('ConversationSettingsSheet', () {
    late _FakeChatRepository repo;
    late ChatSession session;

    Widget wrap() => ProviderScope(
      overrides: [
        chatRepositoryProvider.overrideWithValue(repo),
        settingsProvider.overrideWith(_FakeSettingsController.new),
        modelsControllerProvider.overrideWith(_FakeModelsController.new),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () =>
                  showConversationSettingsSheet(context, session: session),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    setUp(() {
      repo = _FakeChatRepository();
      session = ChatSession(
        id: 's1',
        title: 'Test chat',
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      );
      repo.saveSession(session);
    });

    testWidgets('shows model and generation preset sections', (tester) async {
      await tester.pumpWidget(wrap());
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('Conversation settings'), findsOneWidget);
      expect(find.text('MODEL'), findsOneWidget);
      expect(find.text('GENERATION PRESET'), findsOneWidget);
      expect(find.text('Use default'), findsOneWidget);
    });

    testWidgets('pinning a model updates the session', (tester) async {
      await tester.pumpWidget(wrap());
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      final model = ModelCatalog.all.first;
      await tester.tap(find.text(model.name));
      await tester.pumpAndSettle();

      expect(repo.loadSession('s1')?.modelId, model.id);
    });

    testWidgets('enabling the preset switch adds generation overrides', (
      tester,
    ) async {
      await tester.pumpWidget(wrap());
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Custom preset for this chat'));
      await tester.pumpAndSettle();

      expect(repo.loadSession('s1')?.generationOverrides, isNotNull);
      await tester.scrollUntilVisible(
        find.text('Temperature'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Temperature'), findsOneWidget);
    });
  });
}
