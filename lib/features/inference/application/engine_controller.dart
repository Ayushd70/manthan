import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manthan/core/providers.dart';
import 'package:manthan/features/inference/data/engine_factory.dart';
import 'package:manthan/features/inference/domain/engine_kind.dart';
import 'package:manthan/features/inference/domain/generation_config.dart';
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
    this.requestedModelId,
    this.activeConfig = const GenerationConfig(),
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

  /// Catalog id most recently requested via [EngineController.activate],
  /// even if it fell back to the mock engine (e.g. not downloaded). Used to
  /// detect "should we retry" without confusing a deliberate fallback for a
  /// pending switch.
  final String? requestedModelId;

  /// Generation config the engine was loaded with (global or a
  /// per-conversation override), so callers can detect a mismatch.
  final GenerationConfig activeConfig;

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
    String? Function()? requestedModelId,
    GenerationConfig? activeConfig,
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
      requestedModelId: requestedModelId != null
          ? requestedModelId()
          : this.requestedModelId,
      activeConfig: activeConfig ?? this.activeConfig,
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
    requestedModelId,
    activeConfig,
    displayName,
    kind,
    usingFallback,
    error,
  ];
}

/// Owns the currently loaded [LlmEngine] and handles loading / switching.
class EngineController extends Notifier<EngineRuntimeState> {
  // Tracked separately from `state` because `onDispose` callbacks run after
  // the provider has already been torn down, so reading `state` there is
  // disallowed by Riverpod.
  LlmEngine? _engine;

  // Guards against overlapping activate() calls (e.g. the startup
  // activation racing a session switch) clobbering each other's result —
  // only the most recently *started* call is allowed to publish state.
  int _activationToken = 0;

  @override
  EngineRuntimeState build() {
    ref.onDispose(() => _engine?.dispose());
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
  ///
  /// [configOverride] takes precedence over the global generation config in
  /// Settings — used for per-conversation presets. When null, the global
  /// config is used.
  Future<void> activate(
    String? modelId, {
    GenerationConfig? configOverride,
  }) async {
    final token = ++_activationToken;
    final settings = ref.read(settingsProvider);
    final config = configOverride ?? settings.generationConfig;

    await _engine?.dispose();
    if (token != _activationToken) return;
    _engine = null;

    state = state.copyWith(
      status: EngineStatus.loading,
      requestedModelId: () => modelId,
      error: () => null,
    );

    final model = modelId == null ? null : ModelCatalog.byId(modelId);

    // Fall back to the always-available mock engine when no real model is
    // selected, or the selected file is not present on disk.
    if (model == null || model.engineKind == EngineKind.mock) {
      await _loadMock(config: config, token: token);
      return;
    }

    final storage = ref.read(modelStorageProvider);
    if (!await storage.isDownloaded(model)) {
      await _loadMock(
        config: config,
        token: token,
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
      if (token != _activationToken) {
        await engine.dispose();
        return;
      }
      _engine = engine;
      state = EngineRuntimeState(
        status: EngineStatus.ready,
        engine: engine,
        activeModelId: model.id,
        requestedModelId: modelId,
        activeConfig: config,
        displayName: model.name,
        kind: model.engineKind,
      );
    } on Object catch (e) {
      debugPrint('Engine load failed: $e');
      await _loadMock(
        config: config,
        token: token,
        usingFallback: true,
        note: e.toString(),
      );
    }
  }

  /// Reloads the active model picking up the latest generation config.
  Future<void> reloadActive() => activate(state.activeModelId);

  Future<void> _loadMock({
    required GenerationConfig config,
    required int token,
    bool usingFallback = false,
    String? note,
  }) async {
    final engine = EngineFactory.mock();
    await engine.load(modelPath: '', config: config);
    if (token != _activationToken) {
      await engine.dispose();
      return;
    }
    _engine = engine;
    state = EngineRuntimeState(
      status: EngineStatus.ready,
      engine: engine,
      requestedModelId: state.requestedModelId,
      activeConfig: config,
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
