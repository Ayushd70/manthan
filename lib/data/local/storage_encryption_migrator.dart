import 'package:manthan/data/local/entities.dart';
import 'package:manthan/data/local/field_cipher.dart';
import 'package:manthan/objectbox.g.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// One-shot migration that encrypts legacy plaintext ObjectBox string fields.
///
/// Idempotent: rows already prefixed with `enc:v1:` are left untouched. Sets
/// [versionKey] in SharedPreferences when finished so later launches skip work.
abstract final class StorageEncryptionMigrator {
  /// Prefs key tracking the at-rest encryption schema version.
  static const versionKey = 'storage.atRestVersion';

  /// Current encryption schema version.
  static const currentVersion = 1;

  /// Encrypts any plaintext sensitive fields when the stored version is behind.
  static Future<void> migrateIfNeeded({
    required SharedPreferences prefs,
    required Store store,
    required FieldCipher cipher,
  }) async {
    final version = prefs.getInt(versionKey) ?? 0;
    if (version >= currentVersion) return;

    _migrateSessions(store.box<ChatSessionEntity>(), cipher);
    _migrateMessages(store.box<ChatMessageEntity>(), cipher);
    _migrateDocuments(store.box<DocumentEntity>(), cipher);
    _migrateChunks(store.box<DocumentChunkEntity>(), cipher);
    _migratePrompts(store.box<SavedPromptEntity>(), cipher);

    await prefs.setInt(versionKey, currentVersion);
  }

  static void _migrateSessions(Box<ChatSessionEntity> box, FieldCipher cipher) {
    final all = box.getAll();
    for (final entity in all) {
      var dirty = false;
      if (!FieldCipher.isEncrypted(entity.title) && entity.title.isNotEmpty) {
        entity.title = cipher.encrypt(entity.title);
        dirty = true;
      }
      final overrides = entity.generationOverridesJson;
      if (overrides != null &&
          overrides.isNotEmpty &&
          !FieldCipher.isEncrypted(overrides)) {
        entity.generationOverridesJson = cipher.encrypt(overrides);
        dirty = true;
      }
      if (dirty) box.put(entity);
    }
  }

  static void _migrateMessages(Box<ChatMessageEntity> box, FieldCipher cipher) {
    final all = box.getAll();
    for (final entity in all) {
      if (entity.text.isEmpty || FieldCipher.isEncrypted(entity.text)) continue;
      entity.text = cipher.encrypt(entity.text);
      box.put(entity);
    }
  }

  static void _migrateDocuments(Box<DocumentEntity> box, FieldCipher cipher) {
    final all = box.getAll();
    for (final entity in all) {
      if (entity.title.isEmpty || FieldCipher.isEncrypted(entity.title)) {
        continue;
      }
      entity.title = cipher.encrypt(entity.title);
      box.put(entity);
    }
  }

  static void _migrateChunks(
    Box<DocumentChunkEntity> box,
    FieldCipher cipher,
  ) {
    final all = box.getAll();
    for (final entity in all) {
      var dirty = false;
      if (entity.content.isNotEmpty &&
          !FieldCipher.isEncrypted(entity.content)) {
        entity.content = cipher.encrypt(entity.content);
        dirty = true;
      }
      if (entity.documentTitle.isNotEmpty &&
          !FieldCipher.isEncrypted(entity.documentTitle)) {
        entity.documentTitle = cipher.encrypt(entity.documentTitle);
        dirty = true;
      }
      if (dirty) box.put(entity);
    }
  }

  static void _migratePrompts(Box<SavedPromptEntity> box, FieldCipher cipher) {
    final all = box.getAll();
    for (final entity in all) {
      var dirty = false;
      if (entity.title.isNotEmpty && !FieldCipher.isEncrypted(entity.title)) {
        entity.title = cipher.encrypt(entity.title);
        dirty = true;
      }
      if (entity.content.isNotEmpty &&
          !FieldCipher.isEncrypted(entity.content)) {
        entity.content = cipher.encrypt(entity.content);
        dirty = true;
      }
      if (dirty) box.put(entity);
    }
  }
}
