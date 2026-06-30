import 'dart:typed_data';

import 'package:equatable/equatable.dart';

/// Who authored a [ChatMessage].
enum ChatRole {
  /// The human using the app.
  user,

  /// The on-device model.
  assistant,

  /// A system/preamble instruction (not rendered as a bubble).
  system,
}

/// A single message within a conversation.
///
/// Immutable; UI state transitions (e.g. streaming) are expressed by producing
/// updated copies via [copyWith].
class ChatMessage extends Equatable {
  const ChatMessage({
    required this.id,
    required this.role,
    required this.text,
    required this.createdAt,
    this.images = const <Uint8List>[],
    this.isStreaming = false,
    this.isError = false,
    this.tokensPerSecond,
    this.tokenCount,
    this.sources = const <String>[],
  });

  /// Locally unique identifier (uuid v4).
  final String id;

  /// Author of the message.
  final ChatRole role;

  /// Rendered text content (markdown for assistant messages).
  final String text;

  /// Optional attached image bytes (multimodal input).
  final List<Uint8List> images;

  /// When the message was created.
  final DateTime createdAt;

  /// True while the assistant response is still being streamed.
  final bool isStreaming;

  /// True if this message represents a generation failure.
  final bool isError;

  /// Measured decoding speed for completed assistant messages.
  final double? tokensPerSecond;

  /// Number of generated tokens (assistant messages).
  final int? tokenCount;

  /// Document titles/snippets cited by a RAG-grounded answer.
  final List<String> sources;

  /// True when this message carries one or more images.
  bool get hasImages => images.isNotEmpty;

  ChatMessage copyWith({
    String? text,
    bool? isStreaming,
    bool? isError,
    double? tokensPerSecond,
    int? tokenCount,
    List<String>? sources,
  }) {
    return ChatMessage(
      id: id,
      role: role,
      text: text ?? this.text,
      images: images,
      createdAt: createdAt,
      isStreaming: isStreaming ?? this.isStreaming,
      isError: isError ?? this.isError,
      tokensPerSecond: tokensPerSecond ?? this.tokensPerSecond,
      tokenCount: tokenCount ?? this.tokenCount,
      sources: sources ?? this.sources,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    id,
    role,
    text,
    images.length,
    createdAt,
    isStreaming,
    isError,
    tokensPerSecond,
    tokenCount,
    sources,
  ];
}
