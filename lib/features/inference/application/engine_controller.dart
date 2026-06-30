import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manthan/core/providers.dart';
import 'package:manthan/features/inference/data/engine_factory.dart';
import 'package:manthan/features/inference/domain/engine_kind.dart';
import 'package:manthan/features/inference/domain/llm_engine.dart';
import 'package:manthan/features/models/domain/model_catalog.dart';
import 'package:manthan/features/settings/application/settings_controller.dart';

/// Lifecycle status of the active engine.
enum EngineStatus { idle, loading, ready, error }

/// Observable state of the inference runtime.
class EngineRuntimeState extends Equatable {
  const EngineRuntimeState({
    this.status = EngineStatus.idle,
    this.engine,
    this.activeModelId,
    this.displayName = 'Built-in demo model',
    this.kind = EngineKind.mock,
    this.usingFallback = false,
    this.error,
  });

  /// Current status.
  final EngineStatus status;

  /// The loaded engine, if any.
  final LlmEngine? engine;

  /// Catalog id of the loaded model (null for the mock engine).
  final String? activeModelId;

  /// Human label for the loaded engine/model.
  final String displayName;

  /// Backing runtime kind.
  final EngineKind kind;

  /// True when the requested model was unavailable and we fell back to mock.
  final bool usingFallback;

  /// Error message if [status] is [EngineStatus.error].
  final String? error;

  /// Whether the engine is ready to generate.
  bool get isReady => status == EngineStatus.ready && engine != null;

  EngineRuntimeState copyWith({
    EngineStatus? status,
    LlmEngine? engine,
    String? Function()? activeModelId,
    String? displayName,
    EngineKind? kind,
    bool? usingFallback,
    String? Function()? error,
  }) {
    return EngineRuntimeState(
      status: status ?? this.status,
      engine: engine ?? this.engine,
      activeModelId: activeModelId != null
          ? activeModelId()
          : this.activeModelId,
      displayName: displayName ?? this.displayName,
      kind: kind ?? this.kind,
      usingFallback: usingFallback ?? this.usingFallback,
      error: error != null ? error() : this.error,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    status,
    activeModelId,
    displayName,
    kind,
    usingFallback,
    error,
  ];
}

/// Owns the currently loaded [LlmEngine] and handles loading / switching.
class EngineController extends Notifier<EngineRuntimeState> {
  @override
  EngineRuntimeState build() {
    ref.onDispose(() => state.engine?.dispose());
    // Kick off async initialization based on persisted settings.
    unawaited(
      Future<void>.microtask(() {
        final settings = ref.read(settingsProvider);
        return activate(settings.activeModelId);
      }),
    );
    return const EngineRuntimeState();
  }

  /// Loads the model with [modelId], or the built-in mock when null / missing.
  Future<void> activate(String? modelId) async {
    final settings = ref.read(settingsProvider);
    final config = settings.generationConfig;

    await state.engine?.dispose();

    state = state.copyWith(status: EngineStatus.loading, error: () => null);

    final model = modelId == null ? null : ModelCatalog.byId(modelId);

    // Fall back to the always-available mock engine when no real model is
    // selected, or the selected file is not present on disk.
    if (model == null || model.engineKind == EngineKind.mock) {
      await _loadMock();
      return;
    }

    final storage = ref.read(modelStorageProvider);
    if (!await storage.isDownloaded(model)) {
      await _loadMock(
        usingFallback: true,
        note: '${model.name} is not downloaded yet.',
      );
      return;
    }

    try {
      final engine = EngineFactory.create(model);
      final path = await storage.pathFor(model);
      await engine.load(
        modelPath: path,
        config: config,
        supportImage: model.supportsVision,
      );
      state = EngineRuntimeState(
        status: EngineStatus.ready,
        engine: engine,
        activeModelId: model.id,
        displayName: model.name,
        kind: model.engineKind,
      );
    } on Object catch (e) {
      debugPrint('Engine load failed: $e');
      await _loadMock(usingFallback: true, note: e.toString());
    }
  }

  /// Reloads the active model picking up the latest generation config.
  Future<void> reloadActive() => activate(state.activeModelId);

  Future<void> _loadMock({bool usingFallback = false, String? note}) async {
    final engine = EngineFactory.mock();
    await engine.load(
      modelPath: '',
      config: ref.read(settingsProvider).generationConfig,
    );
    state = EngineRuntimeState(
      status: EngineStatus.ready,
      engine: engine,
      usingFallback: usingFallback,
      error: note,
    );
  }
}

/// Global engine runtime provider.
final engineControllerProvider =
    NotifierProvider<EngineController, EngineRuntimeState>(
      EngineController.new,
    );
