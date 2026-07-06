import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manthan/core/providers.dart';
import 'package:manthan/data/local/entities.dart';
import 'package:manthan/features/inference/data/embedding_factory.dart';
import 'package:manthan/features/inference/domain/embedding_engine.dart';
import 'package:manthan/features/models/application/models_controller.dart';
import 'package:manthan/features/models/domain/model_catalog.dart';

/// Lifecycle status of the active embedding engine.
enum EmbeddingStatus { idle, loading, ready, error }

/// Observable state of the embedding runtime used by RAG.
class EmbeddingRuntimeState extends Equatable {
  const EmbeddingRuntimeState({
    this.status = EmbeddingStatus.idle,
    this.engine,
    this.isUsingMock = true,
    this.dimensions = kEmbeddingDimensions,
    this.error,
  });

  final EmbeddingStatus status;
  final EmbeddingEngine? engine;
  final bool isUsingMock;
  final int dimensions;
  final String? error;

  bool get isReady => status == EmbeddingStatus.ready && engine != null;

  EmbeddingRuntimeState copyWith({
    EmbeddingStatus? status,
    EmbeddingEngine? engine,
    bool? isUsingMock,
    int? dimensions,
    String? Function()? error,
  }) {
    return EmbeddingRuntimeState(
      status: status ?? this.status,
      engine: engine ?? this.engine,
      isUsingMock: isUsingMock ?? this.isUsingMock,
      dimensions: dimensions ?? this.dimensions,
      error: error != null ? error() : this.error,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    status,
    isUsingMock,
    dimensions,
    error,
  ];
}

/// Owns the embedding engine used for document search (RAG).
class EmbeddingController extends Notifier<EmbeddingRuntimeState> {
  @override
  EmbeddingRuntimeState build() {
    ref
      ..onDispose(() => state.engine?.dispose())
      ..listen(modelsControllerProvider, (prev, next) {
        final id = ModelCatalog.embedding.id;
        final wasReady = prev?[id]?.isReady ?? false;
        final isReady = next[id]?.isReady ?? false;
        if (wasReady != isReady) {
          unawaited(activate());
        }
      });

    unawaited(Future<void>.microtask(activate));
    return const EmbeddingRuntimeState();
  }

  /// Loads EmbeddingGemma when downloaded, otherwise the mock embedder.
  Future<void> activate() async {
    await state.engine?.dispose();

    state = state.copyWith(
      status: EmbeddingStatus.loading,
      error: () => null,
    );

    const model = ModelCatalog.embedding;
    final storage = ref.read(modelStorageProvider);

    if (!await storage.isDownloaded(model)) {
      await _loadMock();
      return;
    }

    try {
      final paths = await storage.embeddingPathsFor(model);
      final engine = EmbeddingFactory.gemma();
      await engine.load(
        modelPath: paths.modelPath,
        tokenizerPath: paths.tokenizerPath,
        iosTokenizerPath: paths.iosTokenizerPath,
      );
      if (engine.dimensions != kEmbeddingDimensions) {
        throw StateError(
          'Expected $kEmbeddingDimensions-d embeddings, got ${engine.dimensions}',
        );
      }
      state = EmbeddingRuntimeState(
        status: EmbeddingStatus.ready,
        engine: engine,
        isUsingMock: false,
        dimensions: engine.dimensions,
      );
    } on Object catch (e) {
      debugPrint('Embedding load failed: $e');
      await _loadMock(note: e.toString());
    }
  }

  Future<void> _loadMock({String? note}) async {
    final engine = EmbeddingFactory.mock();
    await engine.load(modelPath: '');
    state = EmbeddingRuntimeState(
      status: EmbeddingStatus.ready,
      engine: engine,
      error: note,
    );
  }

  /// Waits until an embedder is loaded (mock or Gemma).
  Future<void> ensureReady() async {
    if (state.isReady) return;
    for (var i = 0; i < 100; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 30));
      if (state.isReady) return;
    }
    throw StateError('Embedding engine did not become ready in time');
  }
}

/// Global embedding runtime provider.
final embeddingControllerProvider =
    NotifierProvider<EmbeddingController, EmbeddingRuntimeState>(
      EmbeddingController.new,
    );
