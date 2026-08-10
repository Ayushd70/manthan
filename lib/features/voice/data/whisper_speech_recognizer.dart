import 'package:manthan/features/voice/domain/speech_recognizer.dart';

/// Placeholder Whisper.cpp backend.
///
/// Keeps the [SpeechRecognizer] seam ready for a future fully-offline
/// whisper.cpp / `whisper_ggml` integration. Until a Whisper model is bundled
/// and wired, [initialize] returns false so the UI falls back gracefully.
class WhisperSpeechRecognizer implements SpeechRecognizer {
  bool _available = false;

  @override
  bool get isAvailable => _available;

  @override
  bool get isListening => false;

  @override
  Future<bool> initialize() async {
    // Offline Whisper is not shipped yet — signal unavailability so callers
    // keep using the platform STT backend (or show a clear disabled state).
    _available = false;
    return false;
  }

  @override
  Future<void> startListening({
    required void Function(String text, {required bool isFinal}) onResult,
  }) async {
    throw StateError(
      'WhisperSpeechRecognizer is not available yet. '
      'Use the platform speech recognizer, or wait for the Whisper model download.',
    );
  }

  @override
  Future<void> stopListening() async {}
}
