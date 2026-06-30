import 'package:equatable/equatable.dart';
import 'package:manthan/features/chat/domain/chat_message.dart';

/// A conversation thread containing an ordered list of [ChatMessage]s.
class ChatSession extends Equatable {
  const ChatSession({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    this.messages = const <ChatMessage>[],
    this.modelId,
    this.documentScoped = false,
  });

  /// Locally unique identifier (uuid v4).
  final String id;

  /// Display title (auto-derived from the first user message).
  final String title;

  /// Creation timestamp.
  final DateTime createdAt;

  /// Last activity timestamp (used for sorting).
  final DateTime updatedAt;

  /// Ordered messages, oldest first.
  final List<ChatMessage> messages;

  /// The model used for this session, if any.
  final String? modelId;

  /// True when the conversation is grounded against imported documents (RAG).
  final bool documentScoped;

  ChatSession copyWith({
    String? title,
    DateTime? updatedAt,
    List<ChatMessage>? messages,
    String? modelId,
    bool? documentScoped,
  }) {
    return ChatSession(
      id: id,
      title: title ?? this.title,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      messages: messages ?? this.messages,
      modelId: modelId ?? this.modelId,
      documentScoped: documentScoped ?? this.documentScoped,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    id,
    title,
    createdAt,
    updatedAt,
    messages,
    modelId,
    documentScoped,
  ];
}
