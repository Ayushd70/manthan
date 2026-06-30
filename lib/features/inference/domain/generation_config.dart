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
