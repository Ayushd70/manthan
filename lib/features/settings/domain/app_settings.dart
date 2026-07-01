import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:manthan/features/inference/domain/generation_config.dart';

/// User-configurable application settings, persisted across launches.
class AppSettings extends Equatable {
  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.activeModelId,
    this.generationConfig = const GenerationConfig(),
    this.huggingFaceToken,
    this.useDynamicColor = true,
    this.autoSpeakReplies = false,
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

  AppSettings copyWith({
    ThemeMode? themeMode,
    String? Function()? activeModelId,
    GenerationConfig? generationConfig,
    String? Function()? huggingFaceToken,
    bool? useDynamicColor,
    bool? autoSpeakReplies,
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
  ];
}
