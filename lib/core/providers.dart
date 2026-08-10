import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manthan/data/local/field_cipher.dart';
import 'package:manthan/data/local/object_box.dart';
import 'package:manthan/data/local/secure_key_store.dart';
import 'package:manthan/features/chat/data/chat_repository.dart';
import 'package:manthan/features/models/data/model_download_service.dart';
import 'package:manthan/features/models/data/model_storage.dart';
import 'package:manthan/features/prompts/data/prompt_repository.dart';
import 'package:manthan/features/rag/data/document_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provides the opened ObjectBox wrapper. Overridden in `main()` with the real
/// instance (and in tests with a temporary store).
final objectBoxProvider = Provider<ObjectBox>(
  (ref) => throw UnimplementedError('objectBoxProvider must be overridden'),
);

/// Provides [SharedPreferences]. Overridden in `main()`.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) =>
      throw UnimplementedError('sharedPreferencesProvider must be overridden'),
);

/// OS-backed secret store for the DEK and sensitive tokens.
/// Overridden in `main()` (and tests with [MemorySecureKeyStore]).
final secureKeyStoreProvider = Provider<SecureKeyStore>(
  (ref) =>
      throw UnimplementedError('secureKeyStoreProvider must be overridden'),
);

/// Field-level AES cipher used by ObjectBox repositories.
///
/// Overridden in `main()` after the DEK is loaded from secure storage.
final fieldCipherProvider = Provider<FieldCipher>(
  (ref) => throw UnimplementedError('fieldCipherProvider must be overridden'),
);

/// On-disk model file storage.
final modelStorageProvider = Provider<ModelStorage>((ref) => ModelStorage());

/// Resumable model downloader.
final modelDownloadServiceProvider = Provider<ModelDownloadService>(
  (ref) => ModelDownloadService(storage: ref.watch(modelStorageProvider)),
);

/// Chat persistence.
final chatRepositoryProvider = Provider<ChatRepository>(
  (ref) => ChatRepository(
    ref.watch(objectBoxProvider).store,
    cipher: ref.watch(fieldCipherProvider),
  ),
);

/// RAG document + vector persistence.
final documentRepositoryProvider = Provider<DocumentRepository>(
  (ref) => DocumentRepository(
    ref.watch(objectBoxProvider).store,
    cipher: ref.watch(fieldCipherProvider),
  ),
);

/// Saved system prompt persistence.
final promptRepositoryProvider = Provider<PromptRepository>(
  (ref) => PromptRepository(
    ref.watch(objectBoxProvider).store,
    cipher: ref.watch(fieldCipherProvider),
  ),
);
