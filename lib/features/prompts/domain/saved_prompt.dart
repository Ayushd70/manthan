import 'package:equatable/equatable.dart';

/// A reusable, user-authored system prompt.
class SavedPrompt extends Equatable {
  const SavedPrompt({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
  });

  /// Stable id (uuid).
  final String id;

  /// Short display name, e.g. "Concise coding assistant".
  final String title;

  /// The system prompt text applied to generation config.
  final String content;

  /// When the prompt was saved.
  final DateTime createdAt;

  @override
  List<Object?> get props => <Object?>[id, title, content, createdAt];
}
