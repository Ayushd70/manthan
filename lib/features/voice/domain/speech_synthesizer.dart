/// Abstraction over on-device text-to-speech.
///
/// Implemented today by the platform TTS engine (`flutter_tts`), which uses
/// voices bundled with the OS. The interface keeps the door open for a bundled
/// offline voice without touching callers.
abstract interface class SpeechSynthesizer {
  /// Initializes the synthesizer; returns true if speech output is available.
  Future<bool> initialize();

  /// Whether the synthesizer is ready to speak.
  bool get isAvailable;

  /// Whether audio is currently playing.
  bool get isSpeaking;

  /// Speaks [text] aloud. Replaces any in-flight utterance.
  Future<void> speak(String text);

  /// Stops the current utterance immediately.
  Future<void> stop();

  /// Registers a callback when playback finishes or is cancelled.
  void setCompletionHandler(void Function()? onComplete);
}
