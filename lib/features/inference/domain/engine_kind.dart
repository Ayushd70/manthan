/// The concrete runtime backing a catalog model.
///
/// Manthan deliberately abstracts over more than one inference runtime so it is
/// never locked to a single vendor and can pick the best backend per platform.
enum EngineKind {
  /// A built-in deterministic engine. Requires no model download and powers
  /// the first-run experience, tests, and CI where multi-GB weights are absent.
  mock,

  /// Google LiteRT-LM / MediaPipe via `flutter_gemma` (`.task` / `.litertlm`).
  gemma,

  /// `llama.cpp` via `llama_cpp_dart` FFI (`.gguf`), with NPU/Metal/OpenCL
  /// acceleration where available.
  llamaCpp,

  /// whisper.cpp via `whisper_ggml` (`.bin` ggml) for fully offline speech-to-text.
  whisper;

  /// Short human label.
  String get label => switch (this) {
    EngineKind.mock => 'Built-in demo',
    EngineKind.gemma => 'Gemma (LiteRT-LM)',
    EngineKind.llamaCpp => 'llama.cpp (GGUF)',
    EngineKind.whisper => 'Whisper.cpp',
  };
}
