/// Abstraction over on-device speech-to-text.
///
/// Implemented today by the platform recognizer (`speech_to_text`), which runs
/// on-device on supported hardware. The interface keeps the door open for a
/// bundled Whisper.cpp backend without touching callers.
abstract interface class SpeechRecognizer {
  /// Initializes the recognizer; returns true if speech input is available.
  Future<bool> initialize();

  /// Whether the recognizer is ready to listen.
  bool get isAvailable;

  /// Whether a listening session is currently active.
  bool get isListening;

  /// Starts listening, invoking [onResult] with incremental transcripts.
  ///
  /// [onResult] is called with `isFinal: true` for the final transcript.
  Future<void> startListening({
    required void Function(String text, {required bool isFinal}) onResult,
  });

  /// Stops the active listening session.
  Future<void> stopListening();
}
