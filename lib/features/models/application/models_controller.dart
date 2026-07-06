import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manthan/core/providers.dart';
import 'package:manthan/features/models/domain/model_catalog.dart';
import 'package:manthan/features/models/domain/model_download.dart';
import 'package:manthan/features/models/domain/model_info.dart';
import 'package:manthan/features/settings/application/settings_controller.dart';

/// Tracks download/availability state for every catalog model.
class ModelsController extends Notifier<Map<String, ModelDownload>> {
  final Map<String, StreamSubscription<ModelDownload>> _subs =
      <String, StreamSubscription<ModelDownload>>{};

  @override
  Map<String, ModelDownload> build() {
    ref.onDispose(() {
      for (final sub in _subs.values) {
        unawaited(sub.cancel());
      }
    });
    unawaited(Future<void>.microtask(refresh));
    return <String, ModelDownload>{
      for (final m in ModelCatalog.managed) m.id: ModelDownload(modelId: m.id),
    };
  }

  /// Re-scans on-disk storage to determine which models are available.
  Future<void> refresh() async {
    final storage = ref.read(modelStorageProvider);
    final next = Map<String, ModelDownload>.from(state);
    for (final model in ModelCatalog.managed) {
      // Don't clobber an in-flight download.
      if (next[model.id]?.status == ModelDownloadStatus.downloading) continue;
      final downloaded = await storage.isDownloaded(model);
      next[model.id] = ModelDownload(
        modelId: model.id,
        status: downloaded
            ? ModelDownloadStatus.downloaded
            : ModelDownloadStatus.notDownloaded,
        receivedBytes: downloaded ? await storage.sizeOnDisk(model) : 0,
        totalBytes: model.estimatedTotalBytes(isIos: Platform.isIOS),
      );
    }
    state = next;
  }

  /// Starts (or resumes) downloading [model].
  void download(ModelInfo model) {
    if (_subs.containsKey(model.id)) return;
    final service = ref.read(modelDownloadServiceProvider);
    final token = ref.read(settingsProvider).huggingFaceToken;

    final sub = service
        .download(model, authToken: token)
        .listen(
          _set,
          onDone: () {
            unawaited(_subs.remove(model.id)?.cancel());
          },
        );
    _subs[model.id] = sub;
  }

  /// Cancels an in-flight download.
  void cancel(String modelId) {
    ref.read(modelDownloadServiceProvider).cancel(modelId);
    unawaited(_subs.remove(modelId)?.cancel());
    final model = ModelCatalog.byId(modelId);
    _set(
      ModelDownload(
        modelId: modelId,
        totalBytes: model?.estimatedTotalBytes(isIos: Platform.isIOS) ?? 0,
      ),
    );
  }

  /// Deletes a downloaded model from disk.
  Future<void> delete(ModelInfo model) async {
    await ref.read(modelStorageProvider).delete(model);
    // If this was the active model, fall back to the built-in engine.
    final settings = ref.read(settingsProvider);
    if (settings.activeModelId == model.id) {
      await ref.read(settingsProvider.notifier).setActiveModel(null);
    }
    _set(
      ModelDownload(
        modelId: model.id,
        totalBytes: model.sizeBytes,
      ),
    );
  }

  void _set(ModelDownload value) {
    state = <String, ModelDownload>{...state, value.modelId: value};
  }
}

/// Global models provider.
final modelsControllerProvider =
    NotifierProvider<ModelsController, Map<String, ModelDownload>>(
      ModelsController.new,
    );
