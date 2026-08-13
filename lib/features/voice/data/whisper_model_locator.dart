import 'package:manthan/features/models/data/model_storage.dart';
import 'package:manthan/features/models/domain/model_catalog.dart';
import 'package:manthan/features/models/domain/model_info.dart';

/// Resolves which downloaded Whisper.cpp model to load for dictation.
class WhisperModelLocator {
  WhisperModelLocator(this._storage);

  final ModelStorage _storage;

  /// Path of the preferred downloaded model, or null if none is on disk.
  ///
  /// Prefers [preferredId] when that file is present, otherwise the first
  /// downloaded catalog Whisper model (Tiny, then Base).
  Future<String?> pathFor({String? preferredId}) async {
    final model = await resolve(preferredId: preferredId);
    if (model == null) return null;
    return _storage.pathFor(model);
  }

  /// Catalog entry to use, or null when nothing is downloaded.
  Future<ModelInfo?> resolve({String? preferredId}) async {
    if (preferredId != null) {
      final preferred = ModelCatalog.byId(preferredId);
      if (preferred != null &&
          ModelCatalog.isWhisper(preferred.id) &&
          await _storage.isDownloaded(preferred)) {
        return preferred;
      }
    }
    for (final model in ModelCatalog.whisper) {
      if (await _storage.isDownloaded(model)) return model;
    }
    return null;
  }
}
