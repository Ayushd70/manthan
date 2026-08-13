/// Which speech-to-text backend the voice input feature should use.
enum SttBackend {
  /// OS speech recognizer via `speech_to_text` (default).
  platform,

  /// Fully offline Whisper.cpp backend (requires a downloaded ggml model).
  whisper,
}
