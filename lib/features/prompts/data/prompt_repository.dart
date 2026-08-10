import 'package:manthan/data/local/entities.dart';
import 'package:manthan/data/local/field_cipher.dart';
import 'package:manthan/features/prompts/domain/saved_prompt.dart';
import 'package:manthan/objectbox.g.dart';

/// Persists user-saved system prompts.
class PromptRepository {
  PromptRepository(
    Store store, {
    FieldCipher cipher = const PassthroughFieldCipher(),
  }) : _prompts = store.box<SavedPromptEntity>(),
       _cipher = cipher;

  final Box<SavedPromptEntity> _prompts;
  final FieldCipher _cipher;

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
        title: _cipher.encrypt(prompt.title),
        content: _cipher.encrypt(prompt.content),
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
    title: _cipher.decrypt(e.title),
    content: _cipher.decrypt(e.content),
    createdAt: DateTime.fromMillisecondsSinceEpoch(e.createdAtMs),
  );
}
