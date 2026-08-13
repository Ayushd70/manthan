import 'dart:typed_data';

/// Captures microphone audio as 16 kHz mono little-endian PCM16.
///
/// Kept as a seam so speech recognizer implementations can be tested without
/// touching the device microphone.
abstract interface class PcmAudioSource {
  /// Requests microphone permission if needed; returns true when recording
  /// is allowed.
  Future<bool> hasPermission();

  /// Whether a capture session is currently active.
  bool get isRecording;

  /// Starts capturing and returns a stream of PCM16 chunks.
  Future<Stream<Uint8List>> start();

  /// Stops the active capture session.
  Future<void> stop();
}
