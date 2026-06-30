import 'package:manthan/data/local/entities.dart';
import 'package:manthan/features/chat/domain/chat_message.dart';
import 'package:manthan/features/chat/domain/chat_session.dart';
import 'package:manthan/objectbox.g.dart';

/// Persists chat sessions and messages in ObjectBox.
class ChatRepository {
  ChatRepository(Store store)
    : _sessions = store.box<ChatSessionEntity>(),
      _messages = store.box<ChatMessageEntity>();

  final Box<ChatSessionEntity> _sessions;
  final Box<ChatMessageEntity> _messages;

  /// Returns all sessions (most recently updated first) without their messages.
  List<ChatSession> loadSessions() {
    final query =
        (_sessions.query()
              ..order(ChatSessionEntity_.updatedAtMs, flags: Order.descending))
            .build();
    try {
      return query.find().map(_toSessionShallow).toList();
    } finally {
      query.close();
    }
  }

  /// Loads a single session including its ordered messages.
  ChatSession? loadSession(String uid) {
    final session = _sessionByUid(uid);
    if (session == null) return null;
    return _toSessionShallow(session).copyWith(messages: loadMessages(uid));
  }

  /// Loads the ordered messages for [sessionUid].
  List<ChatMessage> loadMessages(String sessionUid) {
    final query = (_messages.query(
      ChatMessageEntity_.sessionUid.equals(sessionUid),
    )..order(ChatMessageEntity_.createdAtMs)).build();
    try {
      return query.find().map(_toMessage).toList();
    } finally {
      query.close();
    }
  }

  /// Inserts or updates a session (metadata only).
  void saveSession(ChatSession session) {
    final existing = _sessionByUid(session.id);
    _sessions.put(
      ChatSessionEntity(
        id: existing?.id ?? 0,
        uid: session.id,
        title: session.title,
        createdAtMs: session.createdAt.millisecondsSinceEpoch,
        updatedAtMs: session.updatedAt.millisecondsSinceEpoch,
        modelId: session.modelId,
        documentScoped: session.documentScoped,
      ),
    );
  }

  /// Inserts or updates a single message.
  void saveMessage(String sessionUid, ChatMessage message) {
    final existing = _messageByUid(message.id);
    _messages.put(
      ChatMessageEntity(
        id: existing?.id ?? 0,
        uid: message.id,
        sessionUid: sessionUid,
        role: message.role.index,
        text: message.text,
        createdAtMs: message.createdAt.millisecondsSinceEpoch,
        isError: message.isError,
        tokensPerSecond: message.tokensPerSecond,
        tokenCount: message.tokenCount,
        imageCount: message.images.length,
      ),
    );
  }

  /// Deletes a session and all of its messages.
  void deleteSession(String uid) {
    final session = _sessionByUid(uid);
    if (session != null) _sessions.remove(session.id);
    final query = _messages
        .query(ChatMessageEntity_.sessionUid.equals(uid))
        .build();
    try {
      _messages.removeMany(query.findIds());
    } finally {
      query.close();
    }
  }

  ChatSessionEntity? _sessionByUid(String uid) {
    final query = _sessions.query(ChatSessionEntity_.uid.equals(uid)).build();
    try {
      return query.findFirst();
    } finally {
      query.close();
    }
  }

  ChatMessageEntity? _messageByUid(String uid) {
    final query = _messages.query(ChatMessageEntity_.uid.equals(uid)).build();
    try {
      return query.findFirst();
    } finally {
      query.close();
    }
  }

  ChatSession _toSessionShallow(ChatSessionEntity e) => ChatSession(
    id: e.uid,
    title: e.title,
    createdAt: DateTime.fromMillisecondsSinceEpoch(e.createdAtMs),
    updatedAt: DateTime.fromMillisecondsSinceEpoch(e.updatedAtMs),
    modelId: e.modelId,
    documentScoped: e.documentScoped,
  );

  ChatMessage _toMessage(ChatMessageEntity e) => ChatMessage(
    id: e.uid,
    role: ChatRole.values[e.role],
    text: e.text,
    createdAt: DateTime.fromMillisecondsSinceEpoch(e.createdAtMs),
    isError: e.isError,
    tokensPerSecond: e.tokensPerSecond,
    tokenCount: e.tokenCount,
  );
}
