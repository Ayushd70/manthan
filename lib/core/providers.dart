import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manthan/data/local/object_box.dart';
import 'package:manthan/features/chat/data/chat_repository.dart';
import 'package:manthan/features/models/data/model_download_service.dart';
import 'package:manthan/features/models/data/model_storage.dart';
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

/// On-disk model file storage.
final modelStorageProvider = Provider<ModelStorage>((ref) => ModelStorage());

/// Resumable model downloader.
final modelDownloadServiceProvider = Provider<ModelDownloadService>(
  (ref) => ModelDownloadService(storage: ref.watch(modelStorageProvider)),
);

/// Chat persistence.
final chatRepositoryProvider = Provider<ChatRepository>(
  (ref) => ChatRepository(ref.watch(objectBoxProvider).store),
);

/// RAG document + vector persistence.
final documentRepositoryProvider = Provider<DocumentRepository>(
  (ref) => DocumentRepository(ref.watch(objectBoxProvider).store),
);
