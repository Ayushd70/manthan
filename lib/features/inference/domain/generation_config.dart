import 'package:equatable/equatable.dart';
import 'package:manthan/features/inference/domain/llm_engine.dart'
    show LlmEngine;

/// Tunable sampling parameters shared by every [LlmEngine].
class GenerationConfig extends Equatable {
  const GenerationConfig({
    this.temperature = 0.8,
    this.topK = 40,
    this.topP = 0.95,
    this.maxTokens = 1024,
    this.systemPrompt,
    this.randomSeed,
  });

  /// Restores a config from [json] produced by [toJson].
  factory GenerationConfig.fromJson(Map<String, Object?> json) {
    return GenerationConfig(
      temperature: (json['temperature'] as num?)?.toDouble() ?? 0.8,
      topK: (json['topK'] as num?)?.toInt() ?? 40,
      topP: (json['topP'] as num?)?.toDouble() ?? 0.95,
      maxTokens: (json['maxTokens'] as num?)?.toInt() ?? 1024,
      systemPrompt: json['systemPrompt'] as String?,
      randomSeed: (json['randomSeed'] as num?)?.toInt(),
    );
  }

  /// Softmax temperature. Higher is more creative, lower is more focused.
  final double temperature;

  /// Top-k sampling cutoff.
  final int topK;

  /// Nucleus (top-p) sampling cutoff.
  final double topP;

  /// Maximum context / generation length in tokens.
  final int maxTokens;

  /// Optional system instruction prepended to the conversation.
  final String? systemPrompt;

  /// Optional deterministic seed (used by tests / reproducible demos).
  final int? randomSeed;

  GenerationConfig copyWith({
    double? temperature,
    int? topK,
    double? topP,
    int? maxTokens,
    String? systemPrompt,
    int? randomSeed,
  }) {
    return GenerationConfig(
      temperature: temperature ?? this.temperature,
      topK: topK ?? this.topK,
      topP: topP ?? this.topP,
      maxTokens: maxTokens ?? this.maxTokens,
      systemPrompt: systemPrompt ?? this.systemPrompt,
      randomSeed: randomSeed ?? this.randomSeed,
    );
  }

  /// Serializes to a JSON-compatible map (for per-session persistence).
  Map<String, Object?> toJson() => <String, Object?>{
    'temperature': temperature,
    'topK': topK,
    'topP': topP,
    'maxTokens': maxTokens,
    'systemPrompt': systemPrompt,
    'randomSeed': randomSeed,
  };

  @override
  List<Object?> get props => <Object?>[
    temperature,
    topK,
    topP,
    maxTokens,
    systemPrompt,
    randomSeed,
  ];
}
