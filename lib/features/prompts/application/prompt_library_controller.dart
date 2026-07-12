import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manthan/core/providers.dart';
import 'package:manthan/features/prompts/data/prompt_repository.dart';
import 'package:manthan/features/prompts/domain/saved_prompt.dart';
import 'package:uuid/uuid.dart';

/// Observable state of the prompt library.
class PromptLibraryState extends Equatable {
  const PromptLibraryState({this.prompts = const <SavedPrompt>[]});

  /// Saved prompts, newest first.
  final List<SavedPrompt> prompts;

  PromptLibraryState copyWith({List<SavedPrompt>? prompts}) {
    return PromptLibraryState(prompts: prompts ?? this.prompts);
  }

  @override
  List<Object?> get props => <Object?>[prompts];
}

/// Manages the user's saved system prompts.
class PromptLibraryController extends Notifier<PromptLibraryState> {
  static const _uuid = Uuid();

  late final PromptRepository _repo;

  @override
  PromptLibraryState build() {
    _repo = ref.read(promptRepositoryProvider);
    return PromptLibraryState(prompts: _repo.list());
  }

  /// Saves a new prompt with [title] and [content].
  void addPrompt({required String title, required String content}) {
    if (title.trim().isEmpty || content.trim().isEmpty) return;
    _repo.save(
      SavedPrompt(
        id: _uuid.v4(),
        title: title.trim(),
        content: content.trim(),
        createdAt: DateTime.now(),
      ),
    );
    _refresh();
  }

  /// Updates an existing prompt's [title] and [content].
  void updatePrompt(
    SavedPrompt prompt, {
    required String title,
    required String content,
  }) {
    if (title.trim().isEmpty || content.trim().isEmpty) return;
    _repo.save(
      SavedPrompt(
        id: prompt.id,
        title: title.trim(),
        content: content.trim(),
        createdAt: prompt.createdAt,
      ),
    );
    _refresh();
  }

  /// Deletes the prompt with [id].
  void deletePrompt(String id) {
    _repo.delete(id);
    _refresh();
  }

  void _refresh() {
    state = state.copyWith(prompts: _repo.list());
  }
}

/// Global prompt library provider.
final promptLibraryControllerProvider =
    NotifierProvider<PromptLibraryController, PromptLibraryState>(
      PromptLibraryController.new,
    );
