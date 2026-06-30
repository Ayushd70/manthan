import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manthan/core/providers.dart';
import 'package:manthan/features/inference/domain/generation_config.dart';
import 'package:manthan/features/settings/domain/app_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Holds and persists [AppSettings].
class SettingsController extends Notifier<AppSettings> {
  static const _kThemeMode = 'settings.themeMode';
  static const _kActiveModel = 'settings.activeModelId';
  static const _kHfToken = 'settings.hfToken';
  static const _kDynamicColor = 'settings.dynamicColor';
  static const _kTemperature = 'settings.temperature';
  static const _kTopK = 'settings.topK';
  static const _kTopP = 'settings.topP';
  static const _kMaxTokens = 'settings.maxTokens';
  static const _kSystemPrompt = 'settings.systemPrompt';

  late final SharedPreferences _prefs;

  @override
  AppSettings build() {
    _prefs = ref.watch(sharedPreferencesProvider);
    return _load();
  }

  AppSettings _load() {
    return AppSettings(
      themeMode: ThemeMode.values[_prefs.getInt(_kThemeMode) ?? 0],
      activeModelId: _prefs.getString(_kActiveModel),
      huggingFaceToken: _prefs.getString(_kHfToken),
      useDynamicColor: _prefs.getBool(_kDynamicColor) ?? true,
      generationConfig: GenerationConfig(
        temperature: _prefs.getDouble(_kTemperature) ?? 0.8,
        topK: _prefs.getInt(_kTopK) ?? 40,
        topP: _prefs.getDouble(_kTopP) ?? 0.95,
        maxTokens: _prefs.getInt(_kMaxTokens) ?? 1024,
        systemPrompt: _prefs.getString(_kSystemPrompt),
      ),
    );
  }

  /// Updates the theme mode.
  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    await _prefs.setInt(_kThemeMode, mode.index);
  }

  /// Toggles dynamic color usage.
  Future<void> setDynamicColor({required bool enabled}) async {
    state = state.copyWith(useDynamicColor: enabled);
    await _prefs.setBool(_kDynamicColor, enabled);
  }

  /// Sets (or clears with null) the active model id.
  Future<void> setActiveModel(String? modelId) async {
    state = state.copyWith(activeModelId: () => modelId);
    if (modelId == null) {
      await _prefs.remove(_kActiveModel);
    } else {
      await _prefs.setString(_kActiveModel, modelId);
    }
  }

  /// Sets (or clears) the Hugging Face token.
  Future<void> setHuggingFaceToken(String? token) async {
    final value = (token == null || token.trim().isEmpty) ? null : token.trim();
    state = state.copyWith(huggingFaceToken: () => value);
    if (value == null) {
      await _prefs.remove(_kHfToken);
    } else {
      await _prefs.setString(_kHfToken, value);
    }
  }

  /// Replaces the generation config.
  Future<void> setGenerationConfig(GenerationConfig config) async {
    state = state.copyWith(generationConfig: config);
    await _prefs.setDouble(_kTemperature, config.temperature);
    await _prefs.setInt(_kTopK, config.topK);
    await _prefs.setDouble(_kTopP, config.topP);
    await _prefs.setInt(_kMaxTokens, config.maxTokens);
    if (config.systemPrompt == null || config.systemPrompt!.isEmpty) {
      await _prefs.remove(_kSystemPrompt);
    } else {
      await _prefs.setString(_kSystemPrompt, config.systemPrompt!);
    }
  }
}

/// Global settings provider.
final settingsProvider = NotifierProvider<SettingsController, AppSettings>(
  SettingsController.new,
);
