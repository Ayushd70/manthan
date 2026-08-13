import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:manthan/features/inference/domain/generation_config.dart';
import 'package:manthan/features/voice/domain/stt_backend.dart';

/// User-configurable application settings, persisted across launches.
class AppSettings extends Equatable {
  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.activeModelId,
    this.generationConfig = const GenerationConfig(),
    this.huggingFaceToken,
    this.useDynamicColor = true,
    this.autoSpeakReplies = false,
    this.hasCompletedOnboarding = false,
    this.toolsEnabled = true,
    this.sttBackend = SttBackend.platform,
    this.whisperModelId,
  });

  /// Light / dark / system theme.
  final ThemeMode themeMode;

  /// Id of the model selected for inference (null = built-in demo engine).
  final String? activeModelId;

  /// Sampling parameters applied when loading a model.
  final GenerationConfig generationConfig;

  /// Optional Hugging Face token for downloading gated models.
  final String? huggingFaceToken;

  /// Whether to use the platform dynamic color palette when available.
  final bool useDynamicColor;

  /// When true, assistant replies are read aloud after generation completes.
  final bool autoSpeakReplies;

  /// Whether the first-run onboarding flow has been completed.
  final bool hasCompletedOnboarding;

  /// When true, the chat loop may invoke on-device tools (calculator, clock).
  final bool toolsEnabled;

  /// Speech-to-text backend used by the chat mic.
  final SttBackend sttBackend;

  /// Catalog id of the Whisper.cpp model used for offline dictation.
  final String? whisperModelId;

  AppSettings copyWith({
    ThemeMode? themeMode,
    String? Function()? activeModelId,
    GenerationConfig? generationConfig,
    String? Function()? huggingFaceToken,
    bool? useDynamicColor,
    bool? autoSpeakReplies,
    bool? hasCompletedOnboarding,
    bool? toolsEnabled,
    SttBackend? sttBackend,
    String? Function()? whisperModelId,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      activeModelId: activeModelId != null
          ? activeModelId()
          : this.activeModelId,
      generationConfig: generationConfig ?? this.generationConfig,
      huggingFaceToken: huggingFaceToken != null
          ? huggingFaceToken()
          : this.huggingFaceToken,
      useDynamicColor: useDynamicColor ?? this.useDynamicColor,
      autoSpeakReplies: autoSpeakReplies ?? this.autoSpeakReplies,
      hasCompletedOnboarding:
          hasCompletedOnboarding ?? this.hasCompletedOnboarding,
      toolsEnabled: toolsEnabled ?? this.toolsEnabled,
      sttBackend: sttBackend ?? this.sttBackend,
      whisperModelId: whisperModelId != null
          ? whisperModelId()
          : this.whisperModelId,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    themeMode,
    activeModelId,
    generationConfig,
    huggingFaceToken,
    useDynamicColor,
    autoSpeakReplies,
    hasCompletedOnboarding,
    toolsEnabled,
    sttBackend,
    whisperModelId,
  ];
}
