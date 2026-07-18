import 'package:equatable/equatable.dart';
import 'package:manthan/features/chat/domain/chat_message.dart';
import 'package:manthan/features/inference/domain/generation_config.dart';

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
    this.generationOverrides,
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

  /// The model pinned to this session, if any (null = follow the global
  /// active model in Settings).
  final String? modelId;

  /// True when the conversation is grounded against imported documents (RAG).
  final bool documentScoped;

  /// Per-conversation sampling/system-prompt overrides (null = use the
  /// global generation config from Settings).
  final GenerationConfig? generationOverrides;

  /// Whether this session pins a specific model or preset, distinct from the
  /// global defaults.
  bool get hasCustomEngineSettings =>
      modelId != null || generationOverrides != null;

  ChatSession copyWith({
    String? title,
    DateTime? updatedAt,
    List<ChatMessage>? messages,
    String? Function()? modelId,
    bool? documentScoped,
    GenerationConfig? Function()? generationOverrides,
  }) {
    return ChatSession(
      id: id,
      title: title ?? this.title,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      messages: messages ?? this.messages,
      modelId: modelId != null ? modelId() : this.modelId,
      documentScoped: documentScoped ?? this.documentScoped,
      generationOverrides: generationOverrides != null
          ? generationOverrides()
          : this.generationOverrides,
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
    generationOverrides,
  ];
}
