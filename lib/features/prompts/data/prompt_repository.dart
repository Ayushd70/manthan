import 'package:manthan/data/local/entities.dart';
import 'package:manthan/features/prompts/domain/saved_prompt.dart';
import 'package:manthan/objectbox.g.dart';

/// Persists user-saved system prompts.
class PromptRepository {
  PromptRepository(Store store) : _prompts = store.box<SavedPromptEntity>();

  final Box<SavedPromptEntity> _prompts;

  /// Lists all saved prompts, newest first.
  List<SavedPrompt> list() {
    final query =
        (_prompts.query()
              ..order(SavedPromptEntity_.createdAtMs, flags: Order.descending))
            .build();
    try {
      return query.find().map(_toDomain).toList();
    } finally {
      query.close();
    }
  }

  /// Inserts or updates a prompt.
  void save(SavedPrompt prompt) {
    final existing = _byUid(prompt.id);
    _prompts.put(
      SavedPromptEntity(
        id: existing?.id ?? 0,
        uid: prompt.id,
        title: prompt.title,
        content: prompt.content,
        createdAtMs: prompt.createdAt.millisecondsSinceEpoch,
      ),
    );
  }

  /// Deletes the prompt with [id], if present.
  void delete(String id) {
    final existing = _byUid(id);
    if (existing != null) _prompts.remove(existing.id);
  }

  SavedPromptEntity? _byUid(String uid) {
    final query = _prompts.query(SavedPromptEntity_.uid.equals(uid)).build();
    try {
      return query.findFirst();
    } finally {
      query.close();
    }
  }

  SavedPrompt _toDomain(SavedPromptEntity e) => SavedPrompt(
    id: e.uid,
    title: e.title,
    content: e.content,
    createdAt: DateTime.fromMillisecondsSinceEpoch(e.createdAtMs),
  );
}
