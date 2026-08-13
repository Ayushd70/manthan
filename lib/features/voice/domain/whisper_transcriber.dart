import 'dart:typed_data';

/// A running live transcription session.
abstract interface class WhisperLiveHandle {
  /// Progressively refined transcripts of audio fed so far (full text, not a
  /// delta).
  Stream<String> get partials;

  /// Finish the session and return the final transcript.
  Future<String> stop();
}

/// Offline speech transcriber (Whisper.cpp).
///
/// Implemented by the `whisper_ggml` adapter; tests inject a fake.
abstract interface class WhisperTranscriber {
  /// Starts a live session against the ggml model at [modelPath].
  ///
  /// [pcm16Stream] must produce 16 kHz mono little-endian PCM16 audio.
  Future<WhisperLiveHandle> startLive({
    required String modelPath,
    required Stream<Uint8List> pcm16Stream,
  });

  /// Releases a model parked in native memory between sessions.
  Future<void> releaseModel();
}
